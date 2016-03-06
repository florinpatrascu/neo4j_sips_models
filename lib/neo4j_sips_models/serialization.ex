defmodule Neo4j.Sips.Models.Serialization do
  def generate(_metadata) do
    quote do
      def serialize_attributes(%__MODULE__{}=model) do
        Neo4j.Sips.Models.Serializer.serialize_attributes(__MODULE__, model)
      end

      def serialize(models) when is_list(models) do
        Neo4j.Sips.Models.Serializer.serialize(__MODULE__, models)
      end

      def serialize(%__MODULE__{}=model) do
        Neo4j.Sips.Models.Serializer.serialize(__MODULE__, model)
      end

      def to_json(models) when is_list(models) do
        Neo4j.Sips.Models.Serializer.to_json(__MODULE__, models)
      end

      def to_json(%__MODULE__{}=model) do
        Neo4j.Sips.Models.Serializer.to_json(__MODULE__, model)
      end
    end
  end
end

