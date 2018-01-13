defmodule CrimsonWeb.PageController do
  use CrimsonWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
