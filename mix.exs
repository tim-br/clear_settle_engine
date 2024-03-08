defmodule ClearSettleEngine.MixProject do
  use Mix.Project

  def project do
    [
      app: :clear_settle_engine,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript_config()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ClearSettleEngine, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.11.1"},
      {:logger_file_backend, "~> 0.0.11"},
      {:postgrex, "~> 0.17.4"},
      {:sweet_xml, "~> 0.7.4"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp escript_config do
    [
      # Replace with an appropriate module
      main_module: MainModule,
      # Specify any additional dependencies your scripts might need:
      include_executables: true
    ]
  end
end
