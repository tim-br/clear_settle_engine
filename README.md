### Installation, Migration, and Running Mix Tasks for ClearSettleEngine

#### Prerequisites:
Ensure you have Elixir and PostgreSQL installed on your machine.

#### Setup:
1. Clone the repository to your local machine.
2. Navigate into the project directory.
3. Initialize the submodule:

Run `git submodule add git@github.com:tim-br/clear_settle_engine_schemas.git lib/clear_settle_engine_schemas`
Then, initialize and pull the submodule data: `git submodule update --init --recursive`

#### Configuration:
Update `config.exs` with your PostgreSQL credentials:
```elixir
config :clear_settle_engine, ClearSettleEngine.Repo,
  username: "your_username",
  password: "your_password",
  database: "clear_settle_engine_dev",
  hostname: "localhost",
  pool_size: 10
```

#### Database Setup:
Run the following commands:
- `mix deps.get` to install dependencies.
- `mix ecto.create` to create the database.
- `mix ecto.migrate` to run migrations.

#### Running Mix Tasks:
- Run `mix run init` to execute the demo task.
- Run `mix run successful_day` to execute the successful_day task.

Ensure you're in the project directory while running these commands.

### Live Demo with Market Events

For a live demonstration of the script interacting with real-time market events, please visit the [Clear Settle Admin GitHub repository](https://github.com/tim-br/clear_settle_admin). This repository provides additional context and showcases the application in a dynamic, live environment, offering insight into how the system performs under actual market conditions.