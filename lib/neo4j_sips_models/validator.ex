defmodule Neo4j.Sips.Models.Validator do
  def add_error(model, field, message) when is_map(model) and is_atom(field) and is_binary(message) do
    errors = Map.get(model, :errors) || %{}
    messages_for_field = Map.get(errors, field) || []
    errors = Map.put errors, field, [message|messages_for_field]
    Map.put model, :errors, errors
  end
end
