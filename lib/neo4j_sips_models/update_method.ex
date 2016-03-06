defmodule Neo4j.Sips.Models.UpdateMethod do
  def generate(_metadata) do
    quote do
      def update_attributes(model, attributes) do
        formatter = fn
          {k,v} when is_binary(k) -> {String.to_atom(k), v}
          {k,v} -> {k,v}
        end

        attributes = attributes
          |> Enum.map(formatter)
          |> Enum.into(%{})

        Map.merge(model, attributes)
      end

      def update_attribute(model, name, value) do
        Map.put(model, name, value)
      end

      def update(%__MODULE__{}=model, attributes) do
        model = update_attributes(model, attributes)
        save(model)
      end
    end
  end
end

