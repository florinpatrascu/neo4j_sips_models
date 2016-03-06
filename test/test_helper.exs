ExUnit.start()

Code.require_file "../support/mock.exs",  __ENV__.file
Code.require_file "../support/person.exs", __ENV__.file

Logger.configure(level: :error)

defmodule Neo4j.Sips.TestHelper do

  @doc """
   Read an entire file into a string.
   Return a tuple of success and data.
   """
  def read_whole_file(path) do
    case File.read(path) do
      {:ok, file} -> file
      {:error, reason} -> {:error, "Could not open #{path} #{file_error_description(reason)}" }
    end
  end

  @doc """
  Open a file stream, and join the lines into a string.
  """
  def stream_file_join(filename) do
    stream = File.stream!(filename)
    Enum.join stream
  end

  defp file_error_description(:enoent), do: "because the file does not exist."
  defp file_error_description(reason), do: "due to #{reason}."
end

# clean up our own test models, before running the tests

# delete_neo4j_sips_test_models = """
#   MATCH (n {neo4j_sips:true}) OPTIONAL MATCH (n)-[r]-() DELETE n,r
# """
# Neo4j.Sips.tx_commit!(Neo4j.Sips.conn, delete_neo4j_sips_test_models)

Process.flag(:trap_exit, true)
