defmodule Model.ValidationsTests do
  use ExUnit.Case
  import Mock

  test "validates presence" do
      {:nok, nil, person} = Person.create(name: "John Doe", age: 30)
      assert Enum.find(person.errors[:email], &(&1 == "model.validation.required")) != nil
    end

    test "validates uniqueness" do
      enable_mock do
        query = """
        START n=node(81776)
        RETURN id(n), n
        """

        expected_response = [
          %{
            "id(n)" => 81776,
                "n" => %{"name" => "John DOE","email" => "john.doe@example.com",
                "age" => 30, "created_at" => "2015-11-02 17:17:17 +0000",
                "updated_at" => "2015-11-02 17:17:17 +0000"}
          }
        ]

        cypher_returns { :ok, expected_response },
          for_query: query

        {:nok, nil, person} = Person.create(name: "John Doe", email: "john.doe@example.com", age: 30)
        assert Enum.find(person.errors[:email], &(&1 == "model.validation.unique")) != nil
      end
    end

    test "validates format" do
      {:nok, nil, person} = Person.create(name: "John Doe", email: "johndoe.fr", age: 30)
      assert Enum.find(person.errors[:email], &(&1 == "model.validation.invalid")) != nil
    end

    test "validates with function" do
      {:nok, nil, person} = Person.create(name: "John Doe", email: "john.doe@example.com", age: -30)
      assert Enum.find(person.errors[:age], &(&1 == "model.validation.invalid_age")) != nil
    end
end
