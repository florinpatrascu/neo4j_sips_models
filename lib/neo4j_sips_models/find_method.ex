defmodule Neo4j.Sips.Models.FindMethod do
  def generate(metadata) do
    quote do
      def find!(), do: find! %{}

      def find!(properties) when is_map(properties) do
        case find Map.to_list(properties) do
          {:ok, result} -> result
          {:error, resp} ->
            raise "Query failed: #{inspect resp}"
        end
      end

      def find!(properties) when is_list(properties) do
        case find(properties) do
          {:ok, result} -> result
          {:error, resp} ->
            raise "Query failed: #{inspect resp}"
        end
      end

      def find!(id) do
        case find(id) do
          {:ok, result} -> result
          {:error, errors} ->
            raise "Query failed: #{inspect errors}"
        end
      end

      def find(), do: find %{}

      def find(properties) when is_map(properties) do
        find Map.to_list(properties)
      end

      def find(properties) when is_list(properties) do
        query = Neo4j.Sips.Models.FindQueryGenerator.query_with_properties(__MODULE__, properties)
        result = Neo4j.Sips.query(Neo4j.Sips.conn, query)

        case result do
          {:ok, []} -> {:ok, []}

          {:ok, rows} ->
            models = rows
            |> parse_node
            |> Enum.map(fn model ->
              unquote generate_after_find_callbacks(metadata)
              model
            end)
            {:ok, models}

          {:error, resp} -> {:nok, resp}
        end
      end

      def find(id) do
        query = Neo4j.Sips.Models.FindQueryGenerator.query_with_id(__MODULE__, id)
        case Neo4j.Sips.query(Neo4j.Sips.conn, query) do
          {:ok, []} -> {:ok, nil}

          {:ok, rows} ->
            model = List.first parse_node(rows)
            unquote generate_after_find_callbacks(metadata)
            {:ok, model}

          {:error, [%{code: "Neo.ClientError.Statement.EntityNotFound", message: _}]} ->
            {:ok, nil}

          {:error, errors} -> {:nok, errors}
        end
      end
    end
  end

  defp generate_after_find_callbacks(metadata) do
    metadata.callbacks
    |> Enum.filter(fn {k,_v} -> k == :after_find end)
    |> Enum.map( fn ({_k, callback}) ->
          quote do
            model = unquote(callback)(model)
          end
        end)
  end
end
