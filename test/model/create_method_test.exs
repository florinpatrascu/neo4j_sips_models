defmodule Model.CreateMethodTest do
  use ExUnit.Case, async: true

  @today Chronos.Formatter.strftime(Chronos.today, "%Y-%0m-%0d")

  setup do
    del_doe_family = """
      MATCH (n {doe_family: true}) OPTIONAL MATCH (n)-[r]-() DELETE n,r
    """
    assert {:ok,_} = Neo4j.Sips.tx_commit(Neo4j.Sips.conn, del_doe_family)
    :ok
  end

  test "parses responses to successful save requests" do
    assert {:ok, person} = Person.create(name: "John DOE", doe_family: true, email: "john.doe@example.com", age: 30)
    assert person.name == "John DOE"
    assert person.email == "john.doe@example.com"
    assert person.age == 30
    assert String.starts_with?(person.created_at, @today)
    assert String.starts_with?(person.updated_at, @today)
  end

  test "parses responses to failed save requests" do
    assert {:ok, _person} = Person.create(name: "John DOE", doe_family: true, email: "john.doe@example.com", age: 30)
    {:nok, _, person} = Person.create(name: "John DOE", email: "john.doe@example.com", enable_validations: true)
    assert Enum.find(person.errors[:email], &(&1 == "model.validation.unique")) != nil
    assert Enum.find(person.errors[:age], &(&1 == "model.validation.invalid_age")) != nil
  end
end
