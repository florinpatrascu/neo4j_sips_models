defmodule Neo4j.Sips.Models.CreateMethod do
  def generate(_metadata) do
    quote do
      def create do
        create %{}
      end

      def create(attributes) do
        resource = build(attributes)
        save(resource)
      end
    end
  end
end

