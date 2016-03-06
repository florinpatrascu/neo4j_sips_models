defmodule Neo4j.Sips.Models.NodeParser do
  def parse(module, data_rows) when is_list(data_rows) do
    data_rows
    |> Enum.group_by(&(&1["id(n)"]))
    |> Enum.map( fn {_, data} ->
          Enum.reduce(data, nil, fn (row, acc) -> parse_row(acc, module, row) end)
          |> module.build
        end)
  end

  def parse(module, data) when is_map(data) do
    parse_row(nil, module, data)
    |> module.build
  end

  def parse_row(model, module, data_row) do
    model = model || parse_id_and_properties(data_row)
    Enum.reduce module.metadata.relationships, model, fn (relationship, model) ->
      relationship_name = relationship.name |> Atom.to_string |> String.downcase

      relationship_data = Map.keys(data_row)
      |> Enum.filter(&(String.starts_with?(&1, relationship_name) && data_row[&1] != nil))
      |> Enum.map(&Map.put(data_row[&1], :id, data_row["id(#{&1})"]))
      |> Enum.filter(&(&1 != nil))
      |> Enum.map(&relationship.related_model.build(&1))

      model = Map.update model, String.to_atom(relationship_name), relationship_data, fn (current_relationship_data) ->
        [current_relationship_data | relationship_data]
        |> List.flatten
        |> Enum.uniq(&(&1.id))
      end

      model
    end
  end

  defp parse_id_and_properties(data) do
    model = %{id: data["id(n)"]}
    func = &Map.merge(model, &1)
    data["n"]
    |> Enum.map(fn {k,v} -> {String.to_atom(k), v} end)
    |> Enum.into(%{})
    |> func.()
  end
end
