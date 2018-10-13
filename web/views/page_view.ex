defmodule MkePolice.PageView do
  use MkePolice.Web, :view

  def format_time(datetime) do
    datetime
    |> Ecto.DateTime.to_iso8601
    |> Timex.parse!("{YYYY}-{0M}-{0D}T{h24}:{m}:{s}")
    |> Timex.format!("{h12}:{m} {am}")
  end

  def in_time_zone(datetime, timezone) do
    tz = Timex.Timezone.get(timezone, Timex.now)

    datetime
    |> Timex.Timezone.convert(tz)
    |> Timex.format!("{h12}:{m} {am}")
  end
end
