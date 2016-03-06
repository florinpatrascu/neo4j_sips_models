defmodule Mock do

  @tx_commit_url "#{Application.get_env(:neo4j_sips, Neo4j)[:url]}/db/data/transaction/commit"

  def init_mocks do
    mock_module Chronos
    :meck.expect(Chronos, :now, fn -> {{2015, 11, 2}, {17, 17, 17}} end)
    mock_module Neo4j.Sips, [:unstick, :passthrough]
    mock_module Neo4j.Sips.Http, [:unstick, :passthrough]
  end

  def unload_mocks do
    :meck.unload(Neo4j.Sips)
    :meck.unload(Neo4j.Sips.Http)
    :meck.unload(Chronos)
  end

  defp mock_module(mod, params \\ []) do
    already_mocked = Process.list
      |> Enum.map(&Process.info/1)
      |> Enum.filter(&(&1 != nil))
      |> Enum.map(&(Keyword.get(&1, :registered_name)))
      |> Enum.filter(&(&1 == :"#{mod}_meck"))
      |> Enum.any?

    unless already_mocked, do: do_mock_module(mod, params)
  end

  defp do_mock_module(mod, []),     do: :meck.new(mod)
  defp do_mock_module(mod, params), do: :meck.new(mod, params)

  defmacro enable_mock(do: block) do
    quote do
      init_mocks
      unquote(block)
      unload_mocks
    end
  end

  defmacro cypher_returns(response, for_query: query) do
    quote bind_quoted: [query: query, response: response] do
      conn = Neo4j.Sips.conn
      :meck.expect(Neo4j.Sips, :query, fn(conn, query) -> response end)
    end
  end

  defmacro cypher_returns(response, for_query: query, with_params: params) do
    quote bind_quoted: [query: query, response: response, params: params] do
      conn = Neo4j.Sips.conn
      :meck.expect(Neo4j.Sips, :query, fn(conn, query, params) -> response end)
    end
  end

  defmacro http_client_returns(response, for_query: query, with_params: params) do
    quote bind_quoted: [query: query, params: params, response: response] do
      request_body = Neo4j.Sips.Utils.format_statements([{query, params}])
      :meck.expect(Neo4j.Sips.Http, :post!, fn(tx_commit_url, body=request_body) -> %{ body: response }
      end)
    end
  end

  defmacro http_client_returns(response, for_queries: queries, with_params: params) do
    quote bind_quoted: [queries: queries, params: params, response: response] do
      request_body = Neo4j.Sips.Utils.format_statements(Enum.zip(queries, params))
      :meck.expect(Neo4j.Sips.Http, :post!, fn(tx_commit_url, body=request_body) -> %{ body: response }
      end)
    end
  end

end
