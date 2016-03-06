defmodule Neo4j.Sips.Models.DeleteMethod do
  def generate(_metadata) do
    quote do
      def delete(%__MODULE__{}=model) do
        cypher = """
        MATCH (n) where ID(n) = #{model.id}
         OPTIONAL MATCH (n)-[r]-()
         DELETE n,r
        """

        case Neo4j.Sips.tx_commit(Neo4j.Sips.conn, cypher) do
          {:ok, _} -> :ok
          {:error, resp} -> {:nok, resp}
        end
      end

      def delete_all() do
        cypher = """
        MATCH (n:#{@label}) OPTIONAL MATCH (n)-[r]-() DELETE n,r
        """

        case Neo4j.Sips.tx_commit(Neo4j.Sips.conn, cypher) do
          {:ok, _} -> :ok
          {:error, resp} -> {:nok, resp}
        end
      end
    end
  end
end
