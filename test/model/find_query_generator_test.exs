defmodule Model.FindQueryGeneratorTest do
  use ExUnit.Case
  alias Neo4j.Sips.Models.FindQueryGenerator

  defmodule ModelWithoutRelationShip do
    use Neo4j.Sips.Model
    field :name
  end

  test "finds by properties value for model without relationships" do
    query = FindQueryGenerator.query_with_properties ModelWithoutRelationShip, name: "john"
    assert query == """
    MATCH (n:Test:Model:FindQueryGeneratorTest:ModelWithoutRelationShip {name: "john"})
    RETURN id(n), n
    """
  end

  test "finds by properties value for model with relationships" do
    query = FindQueryGenerator.query_with_properties Person, name: "john", age: 30
    assert query == """
    MATCH (n:Test:Person {name: "john", age: 30})
    OPTIONAL MATCH (n)-[:FRIEND_OF]-(friend_of)
    OPTIONAL MATCH (n)-[:MARRIED_TO]-(married_to)
    RETURN id(n), n, id(friend_of), friend_of, id(married_to), married_to
    """
  end

  test "finds by properties and relationships" do
    query = FindQueryGenerator.query_with_properties Person, age: 30, friend_of: 1
    assert query == """
    START friend_of=node(1)
    MATCH (n:Test:Person {age: 30})
    MATCH (n)-[:FRIEND_OF]-(friend_of)
    OPTIONAL MATCH (n)-[:MARRIED_TO]-(married_to)
    RETURN id(n), n, id(friend_of), friend_of, id(married_to), married_to
    """
  end

  test "find by id for model without relationships" do
    query = FindQueryGenerator.query_with_id ModelWithoutRelationShip, 1
    assert query == """
    START n=node(1)
    RETURN id(n), n
    """
  end

  test "finds by id for model with relationships" do
    query = FindQueryGenerator.query_with_id Person, 1
    assert query == """
    START n=node(1)
    OPTIONAL MATCH (n)-[:FRIEND_OF]-(friend_of)
    OPTIONAL MATCH (n)-[:MARRIED_TO]-(married_to)
    RETURN id(n), n, id(friend_of), friend_of, id(married_to), married_to
    """
  end

  test "finds by properties and order results by a property" do
    query = FindQueryGenerator.query_with_properties ModelWithoutRelationShip, age: 30, control_clauses: %{order_by: "age"}
    assert query == """
    MATCH (n:Test:Model:FindQueryGeneratorTest:ModelWithoutRelationShip {age: 30})
    RETURN id(n), n
    ORDER BY n.age
    """
  end

  test "finds by properties and order results by a property in descending order" do
    query = FindQueryGenerator.query_with_properties ModelWithoutRelationShip, age: 30, control_clauses: %{order_by: "age DESC"}
    assert query == """
    MATCH (n:Test:Model:FindQueryGeneratorTest:ModelWithoutRelationShip {age: 30})
    RETURN id(n), n
    ORDER BY n.age DESC
    """
  end

  test "finds by properties and order results by several properties" do
    query = FindQueryGenerator.query_with_properties ModelWithoutRelationShip, age: 30, control_clauses: %{order_by: ["age DESC", "name"]}
    assert query == """
    MATCH (n:Test:Model:FindQueryGeneratorTest:ModelWithoutRelationShip {age: 30})
    RETURN id(n), n
    ORDER BY n.age DESC, n.name
    """
  end

  test "finds by properties and limit results" do
    query = FindQueryGenerator.query_with_properties ModelWithoutRelationShip, age: 30, control_clauses: %{limit: 4}
    assert query == """
    MATCH (n:Test:Model:FindQueryGeneratorTest:ModelWithoutRelationShip {age: 30})
    RETURN id(n), n
    LIMIT 4
    """
  end

  test "finds by properties and skip results" do
    query = FindQueryGenerator.query_with_properties ModelWithoutRelationShip, age: 30, control_clauses: %{order_by: "age", skip: 3}
    assert query == """
    MATCH (n:Test:Model:FindQueryGeneratorTest:ModelWithoutRelationShip {age: 30})
    RETURN id(n), n
    ORDER BY n.age
    SKIP 3
    """
  end
end
