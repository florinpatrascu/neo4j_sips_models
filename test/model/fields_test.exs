defmodule Model.FieldsTest do
  use ExUnit.Case

  test "defines fields" do
    field_names = Person.metadata.fields |> Enum.map(fn field -> field.name end)
    assert field_names == [
      :age,
      :created_at,
      :doe_family,
      :email,
      :enable_validations,
      :errors,
      :friend_of,
      :id,
      :married_to,
      :name,
      :neo4j_sips,
      :updated_at,
      :validated
    ]
  end

  test "sets the type of the fields" do
    fields = Person.metadata.fields
    age_field = Enum.find fields, fn field -> field.name == :age end
    assert age_field.type == :integer
  end

  test "defines string fields by default" do
    fields = Person.metadata.fields
    name_field = Enum.find fields, fn field -> field.name == :name end
    assert name_field.type == :string
  end

  test "defines valid default values for field attributes" do
    fields = Person.metadata.fields
    name_field = Enum.find fields, fn field -> field.name == :age end
    assert name_field.required == false
    assert name_field.unique == false
    assert name_field.default == nil
    assert name_field.transient == false
    assert name_field.format == nil
    assert name_field.relationship == false
  end

  test "defines field attributes" do
    fields = Person.metadata.fields
    email_field = Enum.find fields, fn field -> field.name == :email end
    assert email_field.required == true
    assert email_field.unique == true
    assert email_field.default == nil
    assert email_field.transient == false
    assert email_field.format == ~r/\b[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}\b/
    assert email_field.relationship == false
  end
end
