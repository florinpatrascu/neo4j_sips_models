defmodule Neo4j.Sips.SerializationBuffer do
  def add_model(buffer, module, model) do
    relationship_fields = relationship_fields(module)
    serialized_fields = serialized_fields(module)

    keys = Map.keys(model)
    serialized_model = Enum.reduce(keys, %{}, fn (key, acc) ->
      attribute_label = attribute_label(key)

      if Enum.find(serialized_fields, &(&1.name == key)) do
        Map.put acc, attribute_label, attribute_value(model, key)
      else
        if Enum.find(relationship_fields, &(&1.name == key)) do
          related_instances = Map.get(model, key) || []
          Map.put acc, attribute_label, Enum.map(related_instances, &(&1.id))
        else
          acc
        end
      end
    end)

    resource_name = resource_name(module)
    buffer = buffer
    |> Map.put_new(resource_name, [])
    |> Map.update!(resource_name, &( [serialized_model | &1] |> Enum.reverse |> Enum.uniq(fn x -> x["id"] end) ))

    related_instances = Enum.reduce relationship_fields, [], fn (field, acc) ->
      relationship = Enum.find(module.metadata.relationships, &(field_name_for_relationship(&1) == field.name))
      related_instances = Map.get(model, field.name) || []
      instances_data = Enum.map(related_instances, &({&1, relationship.related_model}))
      [instances_data|acc]
    end

    related_instances
    |> List.flatten
    |> Enum.reduce(buffer, fn ({instance, module}, acc) ->
          add_model acc, module, instance
        end)
  end

  defp serialized_fields(module) do
    module.metadata.fields
    |> Enum.filter(&(&1.name == :id or &1.name == :errors or (&1.transient == false and &1.private == false)))
    |> Enum.filter(&(&1.relationship == false))
  end

  defp relationship_fields(module) do
    module.metadata.fields
    |> Enum.filter(&(&1.relationship == true))
  end

  defp attribute_label(key) do
    key |> Atom.to_string |> String.downcase
  end

  defp attribute_value(model, key) do
    value = Map.get(model, key)
    if key == :errors and value != nil do
      format_error_key = fn k -> k |> String.downcase |> String.to_atom end
      value = value |> Enum.map(fn {k,v} -> {format_error_key.(k), v} end) |> Enum.into(%{})
    end
    value
  end

  # Inflex.camelize(:lower)
  def resource_name(module) do
    "#{module}"
    |> String.split(".")
    |> List.last
    |> String.downcase
    |> Inflex.pluralize
  end

  defp field_name_for_relationship(relationship) do
    relationship.name |> Atom.to_string |> String.downcase |> String.to_atom
  end
end
