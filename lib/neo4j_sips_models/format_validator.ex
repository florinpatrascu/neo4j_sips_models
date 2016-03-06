defmodule Neo4j.Sips.Models.FormatValidator do
  import Neo4j.Sips.Models.Validator

  def validate(model, field, format) do
    field_value = Map.get model, field
    if is_valid(field_value, format) do
      model = add_error model, field, "model.validation.invalid"
    end

    model
  end

  defp is_valid(field_value, format) do
    (field_value != nil) and (field_value != "") and (Regex.match?(format, field_value) == false)
  end
end
