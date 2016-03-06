defmodule Neo4j.Sips.Models.Relationship do
  defstruct name: nil, related_model: nil

  def new(name, related_model) do
    %__MODULE__{name: name, related_model: related_model}
  end
end
