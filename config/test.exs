use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :crimson, CrimsonWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :crimson, Crimson.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "jankun",
  password: "mleko0",
  database: "crimson_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
