defmodule Model.SerializationTest do
  use ExUnit.Case

  test "serializes a model" do
    person = Person.build(name: "John DOE", email: "john.doe@example.com", doe_family: true, age: 30)
    assert Person.to_json(person) == "{\"people\":[{\"updated_at\":null,\"neo4j_sips\":true,\"name\":\"John DOE\",\"married_to\":[],\"id\":null,\"friend_of\":[],\"errors\":null,\"email\":\"john.doe@example.com\",\"doe_family\":true,\"created_at\":null,\"age\":30}]}"
  end

  test "serializes an array of models" do
    people = [Person.build(id: 1, name: "John DOE"), Person.build(id: 2, name: "Jane DOE")]
    assert Person.to_json(people) == "{\"people\":[{\"updated_at\":null,\"neo4j_sips\":true,\"name\":\"John DOE\",\"married_to\":[],\"id\":1,\"friend_of\":[],\"errors\":null,\"email\":null,\"doe_family\":false,\"created_at\":null,\"age\":null},{\"updated_at\":null,\"neo4j_sips\":true,\"name\":\"Jane DOE\",\"married_to\":[],\"id\":2,\"friend_of\":[],\"errors\":null,\"email\":null,\"doe_family\":false,\"created_at\":null,\"age\":null}]}"
  end

  test "serializes a model with relationships" do
    john = Person.build(id: 1, name: "John DOE", email: "john.doe@example.com", age: 30)
    jane = Person.build(name: "Jane DOE", email: "jane.doe@example.com", age: 20, married_to: [john])
    assert Person.to_json(jane) == "{\"people\":[{\"updated_at\":null,\"neo4j_sips\":true,\"name\":\"Jane DOE\",\"married_to\":[1],\"id\":null,\"friend_of\":[],\"errors\":null,\"email\":\"jane.doe@example.com\",\"doe_family\":false,\"created_at\":null,\"age\":20},{\"updated_at\":null,\"neo4j_sips\":true,\"name\":\"John DOE\",\"married_to\":[],\"id\":1,\"friend_of\":[],\"errors\":null,\"email\":\"john.doe@example.com\",\"doe_family\":false,\"created_at\":null,\"age\":30}]}"
  end
end
