defmodule Neo4j.Sips.Models.Cypher do
  defmodule CypherQueryResult do
    defstruct results: [], errors: []
  end

  defmacro __using__(_opts) do
    quote do
      def run(q),    do: Neo4j.Sips.query(Neo4j.Sips.conn, q)
      def run(q, p), do: Neo4j.Sips.query(Neo4j.Sips.conn, q, p)
    end
  end
end
