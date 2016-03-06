defmodule Neo4j.Sips.Models.ModelBuilder do
  defmacro build(module) do
    quote do
      %unquote(module){}
    end
  end

  def build(module, params) when is_list(params) do
    func = &Neo4j.Sips.Models.ModelBuilder.build(module, &1)
    params
    |> Enum.map(fn {k,v} -> {Atom.to_string(k), v} end)
    |> Enum.into(%{})
    |> func.()
  end

  def build(module, params) when is_map(params) do
    mapper = fn
      {k,v} when is_binary(k) -> {String.to_atom(k), v}
      {k,v} when is_atom(k) -> {k, v}
      _ -> nil
    end

    params = params
              |> Enum.map(mapper)
              |> Enum.filter(&(&1 != nil))
              |> Enum.into(%{})

    Map.merge(module.build(), params)
  end
end
