defmodule MkePolice.PageController do
  use MkePolice.Web, :controller

  alias MkePolice.Call

  def get_call(conn, %{"id" => id}) do
    calls = Repo.all(from(call in Call, where: call.call_id == ^id, order_by: [asc: call.time]))

    render conn, "get_call.html", calls: calls
  end

  def index(conn, %{"start" => start_date, "end" => end_date}) do

    start_date = Timex.parse!(start_date, "{ISO:Extended}")
    end_date = Timex.parse!(end_date, "{ISO:Extended}")

    calls = get_calls(start_date, end_date)

    render conn, "index.html", calls: calls, start_date: start_date, end_date: end_date
  end

  def index(conn, %{"start" => start_date}) do
    index(conn, %{
      "start" => start_date,
      "end"   => default_end_date()
    })
  end

  def index(conn, _) do
    index(conn, %{
      "start" => Timex.now("America/Chicago") |> Timex.beginning_of_day() |> Timex.format!("{ISO:Extended}"),
      "end"   => default_end_date()
    })
  end

  def csv(conn, %{"action" => "download", "format" => "csv", "start" => %{"month" => start_month, "day" => start_day, "year" => start_year }, "end" => %{"month" => end_month, "day" => end_day, "year" => end_year}}) do
    start_date = Timex.parse!("#{start_year}-#{start_month}-#{start_day}", "{YYYY}-{0M}-{0D}")
    end_date = Timex.parse!("#{end_year}-#{end_month}-#{end_day}", "{YYYY}-{0M}-{0D}")
      |> Timex.end_of_day()


    {:ok, csv_content} = Repo.transaction fn ->
      calls = calls_query(start_date, end_date) |> Repo.stream(max_rows: 50)

      calls 
        |> Stream.map(&Map.from_struct/1) 
        |> Stream.map(fn(call) ->
          {longitude, latitude} = case call.point do 
            nil -> {nil, nil}
            pt  -> {lng, lat} = pt.coordinates 
          end
          call
          |> Map.put(:latitude, latitude)
          |> Map.put(:longitude, longitude)
        end)
        |> CSV.encode(headers: [:id, :time, :location, :latitude, :longitude, :district, :nature, :status] ) 
        |> Enum.to_list()
    end

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("Content-Disposition", "attachment; filename=\"MPD Call Data.csv\"")
    |> send_resp(200, csv_content)
  end

  def csv(conn, _) do
    render conn, "csv.html"
  end


  # JSON view of all calls between start and end (datetimes in ISO:Extended)
  def calls(conn, %{"start" => start_date, "end" => end_date}) do

    start_date = Timex.parse!(start_date, "{ISO:Extended}")
    end_date = Timex.parse!(end_date, "{ISO:Extended}")

    calls = get_calls(start_date, end_date)


    json conn, calls

  end

  def calls(conn, %{"start" => start_date}) do
    calls(conn, %{
      "start" => start_date,
      "end"   => default_end_date()
    })
  end

  def calls(conn, _) do
    calls(conn, %{
      "start" => Timex.now("America/Chicago") |> Timex.beginning_of_day() |> Timex.format!("{ISO:Extended}"),
      "end"   => default_end_date()
    })
  end

  def map(conn, %{"start" => start_date, "end" => end_date}) do
    start_date = Timex.parse!(start_date, "{ISO:Extended}")
    end_date = Timex.parse!(end_date, "{ISO:Extended}")

    calls = get_calls(start_date, end_date)

    render conn, "map.html", calls: calls, start_date: start_date, end_date: end_date
  end

  def map(conn, %{"start" => start_date}) do
    map(conn, %{
      "start" => start_date,
      "end"   => default_end_date()
    })
  end

  def map(conn, _) do
    map(conn, %{
      "start" => Timex.now("America/Chicago") |> Timex.beginning_of_day() |> Timex.format!("{ISO:Extended}"),
      "end"   => default_end_date()
    })
  end

  def elm(conn, _) do 
    render conn, "elm.html"
  end



  defp get_calls(start_date, end_date) do
    subquery = calls_query(start_date, end_date)
    from(c in subquery(subquery), order_by: [desc: c.time])
    |> Repo.all
  end

  defp calls_query(start_date, end_date) do
    subquery = from(call in Call,
      where: call.time >= ^start_date and call.time <= ^end_date,
      distinct: call.call_id,
      order_by: [desc: call.time, desc: call.inserted_at]
    )
  end

  defp default_start_date(), do: Timex.now("America/Chicago") |> Timex.beginning_of_day() |> Timex.format!("{ISO:Extended}")
  defp default_end_date(), do: Timex.now("America/Chicago") |> Timex.format!("{ISO:Extended}")
end
