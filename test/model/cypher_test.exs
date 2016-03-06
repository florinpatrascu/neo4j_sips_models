defmodule CypherTest do
  use ExUnit.Case
  use Neo4j.Sips.Models.Cypher

  setup_all do
    Neo4j.Sips.query(Neo4j.Sips.conn, "MATCH (n {doe_family: true}) OPTIONAL MATCH (n)-[r]-() DELETE n,r")
    assert {:ok, john} = Person.create(name: "John DOE", email: "john.doe@example.com",
                                       age: 30, doe_family: true,
                                       enable_validations: true)
    on_exit(john, fn ->
        assert :ok = Person.delete(john)
      end)
    :ok
  end

  test "execute a query without arguments" do
      query = "match (n:Person {email: \"john.doe@example.com\"}) return n"

      {:ok, results} = run(query)
      assert Enum.count(results) == 1

      item = results |> List.first |> Map.get("n")
      assert item["name"] == "John DOE"
      assert item["email"] == "john.doe@example.com"
  end

  test "execute a query with arguments" do
      query = "match (n {name: {name}}) return n"
      params = %{name: "John DOE"}
      {:ok, results} = run(query, params)
      assert Enum.count(results) == 1

      item = results |> List.first |> Map.get("n")
      assert item["name"] == "John DOE"
      assert item["email"] == "john.doe@example.com"
  end
end
