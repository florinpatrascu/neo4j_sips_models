defmodule Neo4j.Sips.Models.SaveQueryGenerator do
  def query_for_model(model, module) do
    if model.id == nil do
      query_for_new_model(model, module)
    else
      query_for_existing_model(model, module)
    end
  end

  defp query_for_new_model(model, module) do
    query = query_template(model, module)

    date = current_datetime
    properties = model_properties(model, module)
                  |> Map.put(:updated_at, date)
                  |> Map.put(:created_at, date)

    query_params = %{properties: properties}
    {query, query_params}
  end

  defp query_for_existing_model(model, module) do
    properties = model_properties(model, module)
                  |> Map.put("updated_at", current_datetime)
                  |> Enum.map(fn {k,v} -> "n.#{k} = #{inspect v}" end)

    query = """
    #{query_template(model, module)}SET #{Enum.join(properties, ", ")}
    """

    {query, %{}}
  end

  defp model_properties(model, module) do
    module.metadata.fields
      |> Enum.filter(&(&1.transient == false && &1.relationship == false))
      |> Enum.map(&(&1.name))
      |> Enum.map(&({&1, Map.get(model, &1)}))
      |> Enum.filter(fn {k,v} -> k != :id && v != nil end)
      |> Enum.into(Map.new)
  end

  defp current_datetime do
    Chronos.Formatter.strftime(Chronos.now, "%Y-%0m-%0d %H:%M:%S +0000")
  end

  def get_field_value(model, field) do
    value = Map.get(model, field.name) || []
    [value] |> List.flatten |> Enum.map(fn x ->
      cond do
        # TODO: review the is_binary condition when the support for types will have been implemented
        is_integer(x) || is_binary(x) -> x
        is_map(x) -> Map.get(x, :id)
      end
    end)
  end

  defp model_relationships(model, module) do
    for relationship <- module.metadata.relationships do
      module.metadata.fields
        |> Enum.filter(&(&1.relationship == true))
        |> Enum.filter(&(&1.name == normalize(relationship.name)))
        |> Enum.map(&({relationship, get_field_value(model, &1)}))
        |> Enum.filter(fn {_relationship, field_value} -> Enum.empty?(field_value) == false end)
    end
    |> List.flatten
  end

  defp query_template(model, module) do
    if model.id != nil do
      """
      START n=node(#{model.id})
      """
    else
      relationships = model_relationships(model, module)
      if Enum.count(relationships) == 0 do
        query_template_for_new_model_without_relationships(model, module)
      else
        query_template_for_new_model_with_relationships(module, relationships)
      end
    end
  end

  defp query_template_for_new_model_without_relationships(_model, module) do
    """
    CREATE (n:#{module.label} { properties })
    RETURN id(n), n
    """
  end

  defp clauses_for_relationship({relationship, field_value}) do
    start_clauses = Enum.map(field_value, &("#{normalize(relationship.name)}_#{&1}=node(#{&1})"))
    relationship_clauses = Enum.map(field_value, &("CREATE (n)-[:#{relationship.name}]->(#{normalize(relationship.name)}_#{&1})" ))
    return_clauses = Enum.map(field_value, &(["id(#{normalize(relationship.name)}_#{&1})", "#{normalize(relationship.name)}_#{&1}"]))
                     |> List.flatten

    {start_clauses, relationship_clauses, return_clauses}
  end

  defp query_template_for_new_model_with_relationships(module, relationships) do
    clauses = relationships
              |> Enum.map(&(clauses_for_relationship(&1)))

    start_clauses = clauses
                    |> Enum.map(fn {start, _relationship, _return} -> start end)
                    |> List.flatten
                    |> Enum.join(", ")

    relationship_clauses = clauses
                            |> Enum.map(fn {_start, relationship, _return} -> relationship end)
                            |> List.flatten
                            |> Enum.join("\n")

    return_clauses = clauses
                      |> Enum.map(fn {_start, _relationship, return} -> return end)
                      |> List.flatten
                      |> Enum.join(", ")

    """
    START #{start_clauses}
    CREATE (n:#{module.label} { properties })
    #{relationship_clauses}
    RETURN id(n), n, #{return_clauses}
    """
  end

  defp normalize(relationship_name) do
    relationship_name |> Atom.to_string |> String.downcase |> String.to_atom
  end
end
