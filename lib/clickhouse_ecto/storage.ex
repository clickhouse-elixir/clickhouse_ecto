defmodule ClickhouseEcto.Storage do

  @behaviour Ecto.Adapter.Storage

  def storage_up(opts) do
    database = Keyword.fetch!(opts, :database) || raise ":database is nil in repository configuration"
    opts     = Keyword.put(opts, :database, nil)

    command = ~s[CREATE DATABASE IF NOT EXISTS "#{database}"]

    case run_query(command, opts) do
      {:ok, _} ->
        :ok
      {:error, %{code: :database_already_exists}} ->
        {:error, :already_up}
      {:error, error} ->
        {:error, Exception.message(error)}
    end
  end

  defp concat_if(content, nil, _fun),  do: content
  defp concat_if(content, value, fun), do: content <> " " <> fun.(value)

  @doc false
  def storage_down(opts) do
    database = Keyword.fetch!(opts, :database) || raise ":database is nil in repository configuration"
    command  = ~s[DROP DATABASE "#{database}"]
    opts     = Keyword.put(opts, :database, nil)

    case run_query(command, opts) do
      {:ok, _} ->
        :ok
      {:error, %{code: :database_does_not_exists}} ->
        {:error, :already_down}
      {:error, error} ->
        {:error, Exception.message(error)}
    end
  end

  defp run_query(sql, opts) do
#    {:ok, _} = Application.ensure_all_started(:clickhousex)

    opts =
      opts
      |> Keyword.drop([:name, :log])
      |> Keyword.put(:pool, DBConnection.Connection)
      |> Keyword.put(:backoff_type, :stop)

    {:ok, pid} = Task.Supervisor.start_link

    task = Task.Supervisor.async_nolink(pid, fn ->
      HTTPoison.start
      {:ok, conn} = DBConnection.start_link(Clickhousex.Protocol, opts)
      value = ClickhouseEcto.Connection.execute(conn, sql, [], opts)
      GenServer.stop(conn)
      value
    end)

    timeout = Keyword.get(opts, :timeout, 15_000)

    case Task.yield(task, timeout) || Task.shutdown(task) do
      {:ok, {:ok, result}} ->
        {:ok, result}
      {:ok, {:error, error}} ->
        {:error, error}
      {:exit, {%{__struct__: struct} = error, _}}
          when struct in [DBConnection.Error] ->
        {:error, error}
      {:exit, reason}  ->
        {:error, RuntimeError.exception(Exception.format_exit(reason))}
      nil ->
        {:error, RuntimeError.exception("command timed out")}
    end
  end
end
