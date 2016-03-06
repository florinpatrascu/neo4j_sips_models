defmodule Person do
  use Neo4j.Sips.Model

  field :name, required: true
  field :email, required: true, unique: true, format: ~r/\b[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}\b/
  field :age, type: :integer
  field :doe_family, type: :boolean, default: false # used for testing
  field :neo4j_sips, type: :boolean, default: true

  validate_with :check_age

  relationship :FRIEND_OF, Person
  relationship :MARRIED_TO, Person

  def check_age(model) do
    if model.age == nil || model.age <= 0 do
      {:age, "model.validation.invalid_age"}
    end
  end
end


