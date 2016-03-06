defmodule Neo4j.Sips.Models.Serializer do
  alias Neo4j.Sips.SerializationBuffer

  def serialize(module, models) when is_list(models) do
    if Enum.count(models) > 0 do
      Enum.reduce models, %{}, fn (model, acc) ->
        SerializationBuffer.add_model(acc, module, model)
      end
    else
      resource_name = SerializationBuffer.resource_name(module)
      Map.put %{}, resource_name, []
    end
  end

  def serialize(module, model) do
    SerializationBuffer.add_model(%{}, module, model)
  end

  def to_json(module, models) when is_list(models) do
    serialize(module, models) |> transform_to_json
  end

  def to_json(module, model) do
    serialize(module, model) |> transform_to_json
  end

  defp transform_to_json(value, options \\ []) do
    Poison.Encoder.encode(value, options) |> IO.iodata_to_binary
  end
end
