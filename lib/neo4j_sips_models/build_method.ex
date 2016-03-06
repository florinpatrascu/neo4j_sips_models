defmodule Neo4j.Sips.Models.BuildMethod do

  def generate(metadata) do
    quote do
      require Neo4j.Sips.Models.ModelBuilder

      def build, do: Neo4j.Sips.Models.ModelBuilder.build(__MODULE__)
      def build(params) when is_list(params) or is_map(params) do
        Neo4j.Sips.Models.ModelBuilder.build(__MODULE__, params)
      end

      unquote generate_for_required_field(metadata.fields)
      unquote generate_for_each_field(metadata.fields)
    end
  end

  defp generate_for_each_field(fields) do
    fields
    |> Enum.filter(fn field -> field.required == true end)
    |> Enum.map(fn field -> {Atom.to_string(field.name), Macro.var(field.name, __MODULE__)} end)
    |> Enum.map(fn field ->
          function_args = {:%{}, [], [field]}
          quote do
            def build(unquote(function_args)=attributes) do
              attributes = attributes
              |> Enum.map(fn {k,v} -> {String.to_atom(k), v} end)
              |> Enum.into(Map.new)

              Neo4j.Sips.Models.ModelBuilder.build(__MODULE__, attributes)
            end
          end
        end)
  end

  defp generate_for_required_field(fields) do
    required_fields = fields
                      |> Enum.filter(fn field -> field.required == true end)
                      |> Enum.map(fn field -> {Atom.to_string(field.name), Macro.var(field.name, __MODULE__)} end)
    function_args = {:%{}, [], required_fields}

    quote do
      def build(unquote(function_args) = attributes) do
        attributes = attributes
        |> Enum.map(fn {k,v} -> {String.to_atom(k), v} end)
        |> Enum.into(Map.new)

        Neo4j.Sips.Models.ModelBuilder.build(__MODULE__, attributes)
      end
    end
  end
end
