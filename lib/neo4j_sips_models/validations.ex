defmodule Neo4j.Sips.Models.Validations do
  def generate(metadata) do
    quote do
      defp validate(%__MODULE__{}=model) do
        unquote generate_callback_calls(metadata, :before_validation)

        if model.enable_validations == true do
          unquote generate_for_required_fiels(metadata.fields)
          unquote generate_for_unique_fields(metadata.fields)
          unquote generate_for_formatted_fields(metadata.fields)
          unquote generate_for_user_defined(metadata.validation_functions)
        end

        model = Map.put(model, :validated, true)
        unquote generate_callback_calls(metadata, :after_validation)

        model
      end
    end
  end

  def generate_for_required_fiels(fields) do
    required_fields = fields
                      |> Enum.filter(fn field -> field.required == true end)
                      |> Enum.map(fn field -> field.name end)

    quote do
      model = Enum.reduce unquote(required_fields), model, fn (field , model) ->
        Neo4j.Sips.Models.PresenceValidator.validate(model, field)
      end
    end
  end

  defp generate_for_unique_fields(fields) do
    unique_fields = fields
                    |> Enum.filter(fn field -> field.unique == true end)
                    |> Enum.map(fn field -> field.name end)

    quote do
      model = Enum.reduce unquote(unique_fields), model, fn (field, model) ->
        Neo4j.Sips.Models.UniquenessValidator.validate(model, field, __MODULE__)
      end
    end
  end

  defp generate_for_formatted_fields(fields) do
    formatted_fields = fields
                        |> Enum.filter(fn field -> field.format != nil end)
                        |> Enum.map(fn field -> {field.name, field.format} end)

    quote bind_quoted: [formatted_fields: Macro.escape(formatted_fields)] do
      model = Enum.reduce formatted_fields, model, fn ({field, format}, model) ->
        Neo4j.Sips.Models.FormatValidator.validate(model, field, format)
      end
    end
  end

  defp generate_for_user_defined(functions) do
    quote do
      model = Enum.reduce unquote(functions), model, fn (func, model) ->
        Neo4j.Sips.Models.FunctionBasedValidator.validate(model, __MODULE__, func)
      end
    end
  end

  defp generate_callback_calls(metadata, kind) do
    metadata.callbacks
    |> Enum.filter(fn {k, _v} -> k == kind end)
    |> Enum.map(fn {_k, callback} ->
          quote do
            model = unquote(callback)(model)
          end
        end)
  end
end
