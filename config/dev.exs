use Mix.Config

config :app, App.Repo,
  username: System.get_env("POSTGRES_USER"),
  password: System.get_env("POSTGRES_PASSWORD"),
  database: System.get_env("POSTGRES_DATABASE"),
  hostname: System.get_env("POSTGRES_HOST"),
  port: System.get_env("POSTGRES_PORT")