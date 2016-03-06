defmodule Model.UpdateMethodTest do
  use ExUnit.Case
  import Mock

  test "updates the attributes of a model" do
    person = Person.build(name: "John DOE", email: "jdoe@example.com", age: 20)
    person = Person.update_attributes(person, age: 30, email: "john.doe@example.com")
    assert person.age == 30
    assert person.email == "john.doe@example.com"
  end

  test "updates one attribute of a model" do
    person = Person.build(name: "John DOE", age: 20)
    person = Person.update_attribute(person, :age, 30)
    assert person.age == 30
  end

  test "updates and save a model" do
    enable_mock do
      query = """
      START n=node(81776)
      SET n.age = 30, n.email = "john.doe@example.com", n.name = "John DOE", n.updated_at = "2015-11-02 17:17:17 +0000"
      """

      expected_response = [
        %{
          "id(n)" => 81776,
              "n" => %{"name" => "John DOE","email" => "john.doe@example.com", "age" => 30, "created_at" => "2015-11-02 17:17:17 +0000", "updated_at" => "2015-11-02 17:17:17 +0000"}
        }
      ]

      cypher_returns { :ok, expected_response },
        for_query: query,
        with_params: %{}

      person = Person.build(id: 81776, name: "John DOE", email: "john.doe@example.com", age: 18)
      {:ok, person} = Person.update(person, age: 30)

      assert person.id == 81776
      assert person.name == "John DOE"
      assert person.email == "john.doe@example.com"
      assert person.age == 30
      assert person.created_at == "2015-11-02 17:17:17 +0000"
      assert person.updated_at == "2015-11-02 17:17:17 +0000"
    end
  end
end
