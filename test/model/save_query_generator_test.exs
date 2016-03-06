defmodule Model.SaveQueryGeneratorTest do
  use ExUnit.Case
  alias Neo4j.Sips.Models.SaveQueryGenerator

  test "generates valid query for updated model" do
      john = Person.build(id: 1, name: "John Doe", email: "johndoe@example.com", age: 30)
      {query, query_params} = SaveQueryGenerator.query_for_model(john, Person)

      assert String.contains?(query, "START n=node(1)\nSET n.age = 30, n.doe_family = false, n.email = \"johndoe@example.com\", n.name = \"John Doe\", n.neo4j_sips = true, n.updated_at")
      assert query_params == %{}
  end

  test "generates valid query for new model without relationships" do
      john = Person.build(name: "John Doe", email: "johndoe@example.com", age: 30, doe_family: true)
      {query, query_params} = SaveQueryGenerator.query_for_model(john, Person)

      # todo: initialize Chronos differently, or start using Timex
      created_at = query_params[:properties][:created_at]
      updated_at = query_params[:properties][:updated_at]

      assert query == """
      CREATE (n:Test:Person { properties })
      RETURN id(n), n
      """
      assert query_params == %{properties: %{age: 30, created_at: created_at,
        doe_family: true, email: "johndoe@example.com",
        name: "John Doe", neo4j_sips: true, updated_at: updated_at}}
  end

  test "generates valid query for new model with relationships" do
      john = Person.build(name: "John Doe", email: "johndoe@example.com", age: 30,
        friend_of: [1,2], married_to: 3, doe_family: true)

      {query, query_params} = SaveQueryGenerator.query_for_model(john, Person)
      created_at = query_params[:properties][:created_at]
      updated_at = query_params[:properties][:updated_at]

      assert query == """
      START friend_of_1=node(1), friend_of_2=node(2), married_to_3=node(3)
      CREATE (n:Test:Person { properties })
      CREATE (n)-[:FRIEND_OF]->(friend_of_1)
      CREATE (n)-[:FRIEND_OF]->(friend_of_2)
      CREATE (n)-[:MARRIED_TO]->(married_to_3)
      RETURN id(n), n, id(friend_of_1), friend_of_1, id(friend_of_2), friend_of_2, id(married_to_3), married_to_3
      """
      assert query_params == %{properties: %{age: 30, created_at: created_at, doe_family: true,
               email: "johndoe@example.com", name: "John Doe", neo4j_sips: true, updated_at: updated_at}}
  end
end
