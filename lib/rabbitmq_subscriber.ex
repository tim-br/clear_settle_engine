defmodule RabbitMQSubscriber do
  use GenServer

  @moduledoc """
  A GenServer client module for subscribing to RabbitMQ messages using consume.
  """

  # Starts the GenServer
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  # Initializes the RabbitMQ connection, declares the queue, exchange, binds them and consumes messages.
  def init(:ok) do
    # Establish the connection
    host = System.get_env("RABBITMQ_HOST") || "localhost"
    {:ok, connection} = AMQP.Connection.open("amqp://guest:guest@#{host}")
    {:ok, channel} = AMQP.Channel.open(connection)
    {:ok, publisher_channel} = AMQP.Channel.open(connection)

    # Declare the queue and the exchange
    queue = "queue"
    exchange = "start_transactions"
    response_exchange = "response_exchange"
    response_queue = "response_queue"

    AMQP.Queue.declare(channel, queue)
    AMQP.Exchange.declare(channel, exchange, :topic, durable: true)
    AMQP.Queue.bind(channel, queue, exchange)

    # New line: Declare the response exchange
    AMQP.Queue.declare(publisher_channel, response_queue)
    AMQP.Exchange.declare(publisher_channel, response_exchange, :topic, durable: true)
    AMQP.Queue.bind(publisher_channel, response_queue, response_exchange)

    # Start consuming messages
    {:ok, _consumer_tag} =
      AMQP.Basic.consume(
        channel,
        queue,
        nil,
        no_ack: true
      )

    AMQP.Basic.publish(publisher_channel, "response_exchange", "", "already running")

    {:ok, %{channel: channel, connection: connection, publisher_channel: publisher_channel}}
  end

  def handle_info(
        {:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered}},
        %{
          publisher_channel: publisher_channel,
          channel: channel
        } = state
      ) do
    # You might want to run payload consumption in separate Tasks in production
    IO.puts("Received: #{payload}")
    IO.puts(inspect(channel))
    IO.puts(inspect(publisher_channel))

    IO.puts("Check")

    case GenServer.call(SuccessfulDayScheduler, :start_transactions) do
      :ok ->
        IO.puts("Transaction started successfully!!.")

        AMQP.Basic.publish(
          publisher_channel,
          "response_exchange",
          "",
          "transactions_started"
        )

      {:error, :already_running} ->
        IO.puts("Cannot start a new transaction: another transaction is currently in progress.")

        AMQP.Basic.publish(publisher_channel, "response_exchange", "", "already_running")

      _ ->
        IO.puts("Unexpected response from GenServer.")
    end

    {:noreply, state}
  end

  # # Handle cancel which occurs when the consumer is cancelled
  # def handle_info(:basic_cancel, channel) do
  #   IO.puts("Consumer has been cancelled")
  #   {:stop, :normal, channel}
  # end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: consumer_tag}}, chan) do
    {:noreply, chan}
  end

  # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, %{consumer_tag: consumer_tag}}, chan) do
    {:stop, :normal, chan}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:basic_cancel_ok, %{consumer_tag: consumer_tag}}, chan) do
    {:noreply, chan}
  end

  # defp publish_response(channel, response) do
  #   # Specify the exchange and routing key for publishing the response
  #   response_exchange = "response_exchange"
  #   IO.puts("gets here")
  #   # Publish the response to the exchange with the specified routing key
  #   AMQP.Basic.publish(channel, response_exchange, "", response)
  # end
end
