defmodule Airbnb do
  require Logger
  require IO

  def aggr_count_properties(filename) do
    try do
      neighbourhood_index = 28
      property_type_index = 32

      file_stream = File.stream!(filename, [:read, :utf8], :line)
      csv_stream = NimbleCSV.RFC4180.parse_stream(file_stream)

      frequency_map =
        Enum.reduce(csv_stream, %{}, fn row, acc ->

          if length(row) > max(neighbourhood_index, property_type_index) do
            neighbourhood = Enum.at(row, neighbourhood_index, "")
            property_type = Enum.at(row, property_type_index, "")

            key = {neighbourhood, property_type}
            Map.update(acc, key, 1, &(&1 + 1))
          else

            acc
          end
        end)

      result_list =
        Enum.map(frequency_map, fn {{neighbourhood, type}, count} ->
          %{colonia: neighbourhood, tipo: type, total: count}
        end)

      result_list

    rescue
      e in File.Error -> {:error, "File error: #{inspect(e)}"}
      e -> {:error, "An unexpected error occurred: #{inspect(e)}"}
    end
  end
end
