import Config

config :clear_settle_engine,
  ecto_repos: [ClearSettleEngine.Repo]

config :clear_settle_engine, ClearSettleEngine.Repo,
  username: "postgres",
  password: "",
  database: "clear_settle_engine_dev",
  hostname: "localhost",
  pool_size: 10

config :logger,
  backends: [:console],
  level: :error
