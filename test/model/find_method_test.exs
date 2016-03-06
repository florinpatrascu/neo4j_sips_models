defmodule Model.FindMethodTest do
  use ExUnit.Case
  import Mock

  setup_all do
    Neo4j.Sips.query(Neo4j.Sips.conn, "MATCH (n {doe_family: true}) OPTIONAL MATCH (n)-[r]-() DELETE n,r")
    assert {:ok, john} = Person.create(name: "John DOE", email: "john.doe@example.com",
                                       age: 30, doe_family: true,
                                       enable_validations: true)
    assert john != nil
    assert {:ok, jane} = Person.create(name: "Jane DOE", email: "jane.doe@example.com",
                                       age: 25, enable_validations: true, doe_family: true,
                                       married_to: john)
    on_exit({john, jane}, fn ->
        assert :ok = Person.delete(john)
        assert :ok = Person.delete(jane)
      end)
    :ok
  end

  test "find the two Doe family members with results" do
    {:ok, people} = Person.find(doe_family: true)
    assert Enum.count(people) == 2
  end

  test "find Jane DOE" do
    persons = Person.find!(name: "Jane DOE")
    assert length(persons) == 1

    person = List.first(persons)
    assert person.name == "Jane DOE"
    assert person.email == "jane.doe@example.com"
    assert person.age == 25
  end

  test "find John DOE" do
    persons = Person.find!(name: "John DOE")
    assert length(persons) == 1

    person = List.first(persons)
    assert person.name == "John DOE"
    assert person.email == "john.doe@example.com"
    assert person.age == 30
  end

  test "John is married to Jane" do
    jane = Person.find!(name: "Jane DOE") |> List.first
    assert jane.name == "Jane DOE"
    john = Person.find!(name: "John DOE") |> List.first
    assert john.name == "John DOE"

    johns_spouse = john.married_to |> List.first
    assert johns_spouse.name == jane.name
  end

  test "find all with results" do
    enable_mock do
      query = """
      MATCH (n:Test:Person {})
      RETURN id(n), n
      """

      expected_response = [
        %{
          "id(n)" => 81776,
              "n" => %{"name" => "John DOE","email" => "john.doe@example.com", "age" => 30, "created_at" => "2015-11-02 17:17:17 +0000", "updated_at" => "2015-11-02 17:17:17 +0000"}
        },
        %{
          "id(n)" => 81777,
              "n" => %{"name" => "Jane DOE","email" => "jane.doe@example.com", "age" => 20, "created_at" => "2015-11-02 17:17:17 +0000", "updated_at" => "2015-11-02 17:17:17 +0000"}
        }
      ]

      cypher_returns { :ok, expected_response },
        for_query: query

      {:ok, people} = Person.find()
      assert Enum.count(people) == 2

      person = List.first(people)
      assert person.id == 81776
      assert person.name == "John DOE"
      assert person.email == "john.doe@example.com"
      assert person.age == 30
      assert person.created_at == "2015-11-02 17:17:17 +0000"
      assert person.updated_at == "2015-11-02 17:17:17 +0000"
    end
  end

  test "find all without results" do
    enable_mock do
      query = """
      MATCH (n:Test:Person {})
      RETURN id(n), n
      """

      cypher_returns { :ok, [] },
        for_query: query


      {:ok, people} = Person.find()
      assert Enum.count(people) == 0
    end
  end

  test "find all with error" do
    enable_mock do
      query = """
      MATCH (n:Test:Person {})
      RETURN id(n), n
      """

      expected_response = [
        %{
          code: "Neo.ClientError.Statement.InvalidSyntax",
          message: "Invalid input 'T': expected <init> (line 1, column 1)\n\"This is not a valid Cypher Statement.\"\n ^"
        }
      ]

      cypher_returns { :error, expected_response },
        for_query: query

      {:nok, [resp]} = Person.find()
      assert resp.code == "Neo.ClientError.Statement.InvalidSyntax"
      assert resp.message == "Invalid input 'T': expected <init> (line 1, column 1)\n\"This is not a valid Cypher Statement.\"\n ^"
    end
  end

  test "find by id with result" do
    enable_mock do
      query = """
      START n=node(81776)
      RETURN id(n), n
      """

      expected_response = [
        %{
          "id(n)" => 81776,
              "n" => %{"name" => "John DOE","email" => "john.doe@example.com", "age" => 30, "created_at" => "2015-11-02 17:17:17 +0000", "updated_at" => "2015-11-02 17:17:17 +0000"}
        }
      ]

      cypher_returns { :ok, expected_response },
        for_query: query

      {:ok, person} = Person.find(81776)
      assert person.id == 81776
      assert person.name == "John DOE"
      assert person.email == "john.doe@example.com"
      assert person.age == 30
      assert person.created_at == "2015-11-02 17:17:17 +0000"
      assert person.updated_at == "2015-11-02 17:17:17 +0000"
    end
  end

  test "find by id without result" do
    enable_mock do
      query = """
      START n=node(81776)
      RETURN id(n), n
      """

      expected_response = [
        %{
          code: "Neo.ClientError.Statement.EntityNotFound",
          message: "Node with id 81776"
        }
      ]

      cypher_returns { :error, expected_response },
        for_query: query

      {:ok, person} = Person.find(81776)
      assert person == nil
    end
  end

  test "find by properties" do
    enable_mock do
      query = """
      MATCH (n:Test:Person {age: 30})
      RETURN id(n), n
      """

      expected_response = [
        %{
          "id(n)" => 81776,
              "n" => %{"name" => "John DOE","email" => "john.doe@example.com", "age" => 30, "created_at" => "2015-11-02 17:17:17 +0000", "updated_at" => "2015-11-02 17:17:17 +0000"}
        },
        %{
          "id(n)" => 81777,
              "n" => %{"name" => "Jane DOE","email" => "jane.doe@example.com", "age" => 30, "created_at" => "2015-11-02 17:17:17 +0000", "updated_at" => "2015-11-02 17:17:17 +0000"}
        }
      ]

      cypher_returns { :ok, expected_response },
        for_query: query

      {:ok, people} = Person.find(age: 30)
      assert Enum.count(people) == 2

      person = List.first(people)
      assert person.id == 81776
      assert person.name == "John DOE"
      assert person.email == "john.doe@example.com"
      assert person.age == 30
      assert person.created_at == "2015-11-02 17:17:17 +0000"
      assert person.updated_at == "2015-11-02 17:17:17 +0000"
    end
  end

  test "find by properties without results" do
    enable_mock do
      query = """
      MATCH (n:Test:Person {age: 30})
      RETURN id(n), n
      """

      cypher_returns { :ok, [] },
        for_query: query

      {:ok, people} = Person.find(age: 30)
      assert Enum.count(people) == 0
    end
  end

  test "find by properties with error" do
    enable_mock do
      query = """
      MATCH (n:Test:Person {age: 30})
      RETURN id(n), n
      """

      expected_response = [
        %{
          code: "Neo.ClientError.Statement.InvalidSyntax",
          message: "Invalid input 'T': expected <init> (line 1, column 1)\n\"This is not a valid Cypher Statement.\"\n ^"
        }
      ]

      cypher_returns { :error, expected_response },
        for_query: query

      {:nok, [resp]} = Person.find(age: 30)
      assert resp.code == "Neo.ClientError.Statement.InvalidSyntax"
      assert resp.message == "Invalid input 'T': expected <init> (line 1, column 1)\n\"This is not a valid Cypher Statement.\"\n ^"
    end
  end
end
