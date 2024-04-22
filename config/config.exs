import Config

config :clear_settle_engine,
  ecto_repos: [ClearSettleEngine.Repo]

config :clear_settle_engine, ClearSettleEngine.Repo,
  username: System.get_env("DB_USERNAME", "postgres"),
  password: System.get_env("DB_PASSWORD", ""),
  database: System.get_env("DB_DATABASE", "clear_settle_engine_dev"),
  hostname: System.get_env("DB_HOST", "localhost"),
  port: System.get_env("DB_PORT", "5432"),
  pool_size: String.to_integer(System.get_env("DB_POOL_SIZE", "10"))

config :logger,
  backends: [:console],
  level: :error
