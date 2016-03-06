defmodule Neo4j.Sips.Models.Struct do
  def generate(metadata) do
    struct_fields = Enum.map(metadata.fields, fn field -> {field.name, field.default} end)
    quote do
      defstruct unquote(struct_fields)
    end
  end
end
