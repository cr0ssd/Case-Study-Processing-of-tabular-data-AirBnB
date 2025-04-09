defmodule Airbnb do
  require IO

  def offer_by_neighbourhood(filename) do
    neighbourhood_index = 28
    accommodates_index = 34
    price_index = 40
    min_row_length = Enum.max([neighbourhood_index, accommodates_index, price_index]) + 1

    try do
      filename
      |> File.stream!([:read, :utf8], :line)
      |> NimbleCSV.RFC4180.parse_stream()
      |> Enum.map(&process_row_for_offer(&1, min_row_length, neighbourhood_index, accommodates_index, price_index))
      |> Enum.filter(&match?({:ok, _}, &1))
      |> Enum.map(&elem(&1, 1))
      |> Enum.group_by(&elem(&1, 0))
      |> Enum.map(&calculate_offer_aggregates/1)
    rescue
      e in File.Error -> {:error, "File error: #{inspect(e)}"}
      e -> {:error, "An unexpected error occurred: #{inspect(e)}"}
    end
  end

  defp process_row_for_offer(row, min_len, n_idx, acc_idx, p_idx) do
    if length(row) >= min_len do
      neighbourhood = Enum.at(row, n_idx)
      acc_str = Enum.at(row, acc_idx)
      price_str = Enum.at(row, p_idx)

      with {:ok, accommodates} <- parse_accommodates(acc_str),
           {:ok, price} <- parse_price(price_str) do

        price_per_person = if accommodates > 0, do: price / accommodates, else: nil

        {:ok, {neighbourhood, accommodates, price_per_person}}
      else
        _error -> :error
      end
    else
      :error
    end
  end

  defp parse_accommodates(acc_str) when is_binary(acc_str) do
    case Integer.parse(acc_str) do
      {int_val, ""} -> {:ok, int_val}
      _ -> :error
    end
  end
  defp parse_accommodates(_), do: :error

  defp parse_price(price_str) when is_binary(price_str) do
    cleaned_str = String.replace(price_str, ["$", ","], "")
    parse_result = Float.parse(cleaned_str)

    case parse_result do
      {float_val, ""} -> {:ok, float_val}
      _ -> :error
    end
  end
  defp parse_price(_), do: :error

  defp calculate_offer_aggregates({neighbourhood, properties_data}) do

    total_capacity = Enum.sum(for {_, acc, _} <- properties_data, do: acc)
    valid_ppps = for {_, _, ppp} <- properties_data, not is_nil(ppp), do: ppp

    average_ppp =
      if Enum.empty?(valid_ppps) do
        0.0
      else
        avg = Enum.sum(valid_ppps) / Enum.count(valid_ppps)
        Float.round(avg, 2)
      end

    %{
      neighbourhood: neighbourhood,
      hosting_capacity: total_capacity,
      average_price_per_person: average_ppp
    }
  end
end
