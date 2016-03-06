defmodule Model.RelationshipTest do
  use ExUnit.Case

  test "defines relationships" do
    relationship_names = Person.metadata.relationships |> Enum.map(&(&1.name))
    relationship_related_models = Person.metadata.relationships |> Enum.map(&(&1.related_model))
    assert relationship_names == [:FRIEND_OF, :MARRIED_TO]
    assert relationship_related_models == [Person, Person]
  end

  test "creates fields for each defined relationship" do
    assert Enum.find(Person.metadata.fields, &(&1.name == :friend_of))
    assert Enum.find(Person.metadata.fields, &(&1.name == :married_to))
  end

  test "defines valid attributes for the relationship fields" do
    field = Enum.find(Person.metadata.fields, &(&1.name == :friend_of))
    assert field.required == false
    assert field.unique == false
    assert field.default == nil
    assert field.transient == false
    assert field.type == :integer
    assert field.format == nil
    assert field.relationship == true
  end
end
