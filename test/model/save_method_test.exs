defmodule Model.SaveMethodTest do
  use ExUnit.Case
  import Mock

  @today Chronos.Formatter.strftime(Chronos.today, "%Y-%0m-%0d")

  setup do
    del_doe_family = """
      MATCH (n {doe_family: true}) OPTIONAL MATCH (n)-[r]-() DELETE n,r
    """
    assert {:ok,_} = Neo4j.Sips.tx_commit(Neo4j.Sips.conn, del_doe_family)
    :ok
  end

  test "successfully saves a new model" do
    person = Person.build(name: "John DOE", email: "john.doe@example.com", age: 20, doe_family: true,)
    {:ok, person} = Person.save(person)

    assert person.email == "john.doe@example.com"
    assert person.name == "John DOE"
    assert person.age == 20
    assert String.starts_with?(person.created_at, @today)
    assert String.starts_with?(person.updated_at, @today)
  end

  test "successfully updates an existing model" do
      person = Person.build(name: "John DOE", email: "john.doe@example.com", doe_family: true, age: 18)
      person = Person.update_attributes(person, age: 30)
      {:ok, person} = Person.save(person)

      assert person.name == "John DOE"
      assert person.email == "john.doe@example.com"
      assert person.age == 30
      assert String.starts_with?(person.created_at, @today)
      assert String.starts_with?(person.updated_at, @today)
  end

  test "parses responses to failed save requests" do
    enable_mock do
      query = """
        START n=node(81776)
        SET n.age = 30, n.email = "john.doe@example.fr", n.name = "John DOE", n.updated_at = "2015-11-02 17:17:17 +0000"
      """

      expected_response = [
        %{
          code: "Neo.ClientError.Statement.InvalidSyntax",
          message: "Invalid input 'T': expected <init> (line 1, column 1)\n\"This is not a valid Cypher Statement.\"\n ^"
        }
      ]

      cypher_returns { :error, expected_response },
        for_query: query,
        with_params: %{}

      person = Person.build(id: 81776, name: "John DOE", email: "john.doe@example.fr", age: 18, enable_validations: false)
      person = Person.update_attributes(person, age: 30)
      {:nok, [resp], _person} = Person.save(person)

      assert resp.code == "Neo.ClientError.Statement.InvalidSyntax"
      assert resp.message == "Invalid input 'T': expected <init> (line 1, column 1)\n\"This is not a valid Cypher Statement.\"\n ^"
    end
  end

end
