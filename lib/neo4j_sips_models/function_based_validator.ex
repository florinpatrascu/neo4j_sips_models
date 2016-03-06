defmodule Neo4j.Sips.Models.FunctionBasedValidator do
  import Neo4j.Sips.Models.Validator

  def validate(model, module, func) when is_atom(func) do
    {function_result, _} = Code.eval_string "#{module}.#{func}(model)", [model: model], [delegate_locals_to: module]
    model = case function_result do
      {field, message} when is_atom(field) and is_binary(message) -> add_error model, field, message
      _ -> model
    end

    model
  end
end
