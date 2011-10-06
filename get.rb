# -*- coding: utf-8 -*-

require 'pp'
require 'kconv'
require 'net/http'
require 'nokogiri'
require 'open-uri'

USER_AGENT = 'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0)'

class Crawler
  def initialize(url, user_agent)
    @url = url
    @user_agent = user_agent
  end

  def doc
    Nokogiri::HTML(raw_html)
  end

  def raw_html
    open(@url, 'User-Agent' => @user_agent).read.toutf8.gsub(/\r/, "\n")
  end
end

class Parser
  def self.exec(doc)
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
      time_table_hours["#{h[0]}"] = h[2] unless h[2].nil?
    end
    time_table_hours.delete('系統')
    time_table_hours
  end

  def self.get_timetable(doc)
    time_table_minutes = Hash.new
    exec(doc).each do |k, v|
      v = v.unpack("a2" * (v.size / 2))
      time_table_minutes["#{k}"] = v
    end
    time_table_minutes
  end
end

if $0 == __FILE__
  url = "http://dia.kanachu.jp/bus/timetable?busstop=16064&pole=7&pole_seq=2&apply=2011/10/03&day=1"
  isehara = Crawler.new(url, USER_AGENT)
  time_table = Parser.get_timetable(isehara.doc)
  pp time_table
end
