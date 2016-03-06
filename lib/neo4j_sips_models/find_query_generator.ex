defmodule Neo4j.Sips.Models.FindQueryGenerator do
  def query_with_id(module, id) do
    relationships = model_relationships(module)
    if Enum.empty?(relationships) do
      query_with_id_without_relationships(id)
    else
      query_with_id_and_relationships(id, relationships)
    end
  end

  def query_with_properties(module, properties) do
    {properties, control_clauses} = get_control_clauses(properties)

    relationships = model_relationships(module)
    if Enum.empty?(relationships) do
      query_with_properties_without_relationships(module, properties)
      |> append_control_clauses(control_clauses)
    else
      query_with_properties_and_relationships(module, properties, relationships)
      |> append_control_clauses(control_clauses)
    end
  end

  defp model_relationships(module) do
    module.metadata.relationships
  end

  def query_with_properties_without_relationships(module, properties) do
    query_params = properties
                    |> Enum.map(fn {k,v} -> "#{k}: #{inspect(v)}" end)
                    |> Enum.join(", ")

    """
    MATCH (n:#{module.label} {#{query_params}})
    RETURN id(n), n
    """
  end

  def query_with_properties_and_relationships(module, properties, relationships) do
    if have_required_relationships?(properties, relationships) do
      query_with_properties_and_required_relationships(module, properties, relationships)
    else
      query_with_properties_and_optional_relationships(module, properties, relationships)
    end
  end

  def query_with_properties_and_required_relationships(module, properties, relationships) do
    is_queried = fn(relationship) ->
      Enum.any?(properties, fn {key,_} -> key == normalize(relationship.name) end)
    end

    start_clauses = relationships
                    |> Enum.map(&normalize(&1.name))
                    |> Enum.map(&({&1, properties[&1]}))
                    |> Enum.filter(fn {_, id} -> id != nil end)
                    |> Enum.map(fn {name, id} -> "#{name}=node(#{id})" end)
                    |> Enum.join(",")

    required_match_clauses = relationships
                              |> Enum.filter(&(is_queried.(&1)))
                              |> Enum.map(&("MATCH (n)-[:#{&1.name}]-(#{normalize(&1.name)})"))
                              |> Enum.join("\n")

    optional_match_clauses = relationships
                              |> Enum.filter(&(is_queried.(&1) == false))
                              |> Enum.map(&("OPTIONAL MATCH (n)-[:#{&1.name}]-(#{normalize(&1.name)})"))
                              |> Enum.join("\n")

    return_clauses = relationships
                      |> Enum.map(&(["id(#{normalize(&1.name)})", normalize(&1.name)]))
                      |> List.flatten
                      |> Enum.join(", ")

    query_params = properties
                    |> Enum.filter(fn {k,_} -> Enum.any?(relationships, &(normalize(&1.name) == k)) == false end)
                    |> Enum.map(fn {k,v} -> "#{k}: #{inspect(v)}" end)
                    |> Enum.join(", ")

    """
    START #{start_clauses}
    MATCH (n:#{module.label} {#{query_params}})
    #{required_match_clauses}
    #{optional_match_clauses}
    RETURN id(n), n, #{return_clauses}
    """
  end

  def query_with_properties_and_optional_relationships(module, properties, relationships) do
    match_clauses = relationships
                    |> Enum.map(&("OPTIONAL MATCH (n)-[:#{&1.name}]-(#{normalize(&1.name)})"))
                    |> Enum.join("\n")

    return_clauses = relationships
                      |> Enum.map(&(["id(#{normalize(&1.name)})", normalize(&1.name)]))
                      |> List.flatten
                      |> Enum.join(", ")

    query_params = properties
                    |> Enum.map(fn {k,v} -> "#{k}: #{inspect(v)}" end)
                    |> Enum.join(", ")

    """
    MATCH (n:#{module.label} {#{query_params}})
    #{match_clauses}
    RETURN id(n), n, #{return_clauses}
    """
  end

  def query_with_id_without_relationships(id) do
    """
    START n=node(#{id})
    RETURN id(n), n
    """
  end

  def query_with_id_and_relationships(id, relationships) do
    match_clauses = relationships
                    |> Enum.map(&("OPTIONAL MATCH (n)-[:#{&1.name}]-(#{normalize(&1.name)})"))
                    |> Enum.join("\n")

    return_clauses = relationships
                      |> Enum.map(&(["id(#{normalize(&1.name)})", normalize(&1.name)]))
                      |> List.flatten
                      |> Enum.join(", ")

    """
    START n=node(#{id})
    #{match_clauses}
    RETURN id(n), n, #{return_clauses}
    """
  end

  defp normalize(relationship_name) do
    relationship_name |> Atom.to_string |> String.downcase |> String.to_atom
  end

  defp have_required_relationships?(properties, relationships) do
    relationship_names = Enum.map(relationships, &(normalize(&1.name)))
    Enum.any? properties, fn {key, _} -> Enum.find(relationship_names, &(&1 == key)) end
  end

  defp get_control_clauses(properties) do
    control_clauses = properties
    |> Keyword.get(:control_clauses, %{})
    |> Map.put_new(:order_by, nil)
    |> Map.put_new(:skip, nil)
    |> Map.put_new(:limit, nil)

    properties = Keyword.delete(properties, :control_clauses)

    {properties, control_clauses}
  end

  defp append_control_clauses(query, %{order_by: nil}=control_clauses), do: append_control_clauses(query, Map.delete(control_clauses, :order_by))
  defp append_control_clauses(query, %{skip: nil}=control_clauses), do: append_control_clauses(query, Map.delete(control_clauses, :skip))
  defp append_control_clauses(query, %{limit: nil}=control_clauses), do: append_control_clauses(query, Map.delete(control_clauses, :limit))

  defp append_control_clauses(query, %{order_by: order_by}=control_clauses) when is_list(order_by) do
    order_clauses = order_by
    |> Enum.map(&("n.#{&1}"))
    |> Enum.join(", ")

    query = """
    #{String.strip(query)}
    ORDER BY #{order_clauses}
    """
    append_control_clauses query, Map.delete(control_clauses, :order_by)
  end

  defp append_control_clauses(query, %{order_by: order_by}=control_clauses) do
    query = """
    #{String.strip(query)}
    ORDER BY n.#{order_by}
    """
    append_control_clauses query, Map.delete(control_clauses, :order_by)
  end

  defp append_control_clauses(query, %{skip: skip}=control_clauses) do
    query = """
    #{String.strip(query)}
    SKIP #{skip}
    """
    append_control_clauses query, Map.delete(control_clauses, :skip)
  end

  defp append_control_clauses(query, %{limit: limit}=control_clauses) do
    query = """
    #{String.strip(query)}
    LIMIT #{limit}
    """
    append_control_clauses query, Map.delete(control_clauses, :limit)
  end

  defp append_control_clauses(query, %{}), do: query
end
