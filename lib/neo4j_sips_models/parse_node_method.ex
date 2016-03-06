defmodule Neo4j.Sips.Models.ParseNodeMethod do
  def generate(_metadata) do
    quote do
      def parse_node(node_data) do
        Neo4j.Sips.Models.NodeParser.parse(__MODULE__, node_data)
      end
    end
  end
end
