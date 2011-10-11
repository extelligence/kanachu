module ApplicationHelper

  def format_str_time(string_time)
      hour_minutes = string_time.unpack("a2" * (string_time.size / 2))
      "#{hour_minutes[0]}:#{hour_minutes[1]}"
  end
end
