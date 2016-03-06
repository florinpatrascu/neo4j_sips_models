defmodule Neo4j.Sips.Models do
  @moduledoc """
  Neo4j.Sips models.

  You can easily define your own Elixir modules like this:

  ```elixir
  defmodule Person do
    use Neo4j.Sips.Model

    field :name, required: true
    field :email, required: true, unique: true, format: ~r/\b[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}\b/
    field :age, type: :integer
    field :doe_family, type: :boolean, default: false # used for testing
    field :neo4j_sips, type: :boolean, default: true

    validate_with :check_age

    relationship :FRIEND_OF, Person
    relationship :MARRIED_TO, Person

    def check_age(model) do
      if model.age == nil || model.age <= 0 do
        {:age, "model.validation.invalid_age"}
      end
    end
  end

  ```

  and use in various scenarios. Example from various tests file:

  ```elixir
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

  ...

  # model find
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

  ...
  """

  @doc false
  def start_link(repo, opts) do
    IO.puts("0980980980980980")
    {:ok, _} = Application.ensure_all_started(:neo4j_sips_models)
    # repo.__mongo_pool__.start_link(opts)
  end

  @doc false
  def stop(pid, timeout) do
    ref = Process.monitor(pid)
    Process.exit(pid, :normal)
    receive do
      {:DOWN, ^ref, _, _, _} -> :ok
    after
      timeout -> exit(:timeout)
    end
    Application.stop(:neo4j_sips_models)
    :ok
  end

end
