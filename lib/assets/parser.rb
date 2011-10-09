# -*- coding: utf-8 -*-

class Parser
  def self.to_array(doc)
    time_table_minutes = []
    raw_timetable(doc).each do |k, v|
      minutes_array = v.unpack("a2" * (v.size / 2))
      minutes_array.each do |m|
        time_table_minutes << [k, m] unless m.empty?
      end
    end
    time_table_minutes
  end

  private
  def self.raw_timetable(doc)
    start_hour = 5
    end_hour   = 26
    time_table_array = []
    time_table_hours = Hash.new

    time_table_xpath = "/html/body/table[2]"
    html_time_table = doc.xpath(time_table_xpath)
    start_hour..end_hour.times do |i|
      content = html_time_table.xpath("tr[#{i - 1}]/td").text
      content.delete!("\n")
      content = content.split
      unless content[0].nil?
        time_table_array << content
      end
    end

    time_table_array.each do |h|
      h[0] = "0#{h[0]}" if h[0].size == 1
      time_table_hours["#{h[0]}"] = h[2] unless h[2].nil?
    end
    time_table_hours.delete('系統')
    time_table_hours.delete('経由')
    time_table_hours
  end
end
