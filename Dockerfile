# Use an official Elixir runtime as a parent image
FROM elixir:latest

# Create and set the working directory
WORKDIR /app

# Copy the mix.exs and mix.lock files to the container
COPY mix.exs mix.lock ./

# Install hex and rebar

RUN mix archive.install github hexpm/hex branch latest --force

RUN mix local.rebar --force
# Install dependencies
RUN mix deps.get

# Copy the rest of your application's code
COPY . .

# Compile the project

RUN mix do compile

# Run the application
CMD ["mix", "run"]
