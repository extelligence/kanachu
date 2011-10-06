# -*- coding: utf-8 -*-

require 'rubygems'
require 'pp'
require 'kconv'
require 'net/http'
require 'nokogiri'
require 'open-uri'

# Set UserAgent
url = "http://dia.kanachu.jp/bus/timetable?busstop=16064&pole=7&pole_seq=2&apply=2011/10/03&day=1"
BOT_USER_AGENT = 'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0)'

raw_html = open(url, 'User-Agent' => BOT_USER_AGENT).read.toutf8.gsub(/\r/, "\n")

#puts raw_html
doc = Nokogiri::HTML(raw_html)
#pp doc

#target = "/html/body/table[2]/tr[8]/td[2]/table/tr[2]/td/table/tr/td"
time_table_xpath = "/html/body/table[2]"
html_time_table = doc.xpath(time_table_xpath)
#puts html_time_table.xpath("tr/td[2]/table/tr[2]").text

start_hour = 5
end_hour = 26

time_table_array = []
start_hour..end_hour.times do |i|
  hoge = html_time_table.xpath("tr[#{i - 1}]/td").text
  hoge.delete!("\n")
  hoge = hoge.split
  unless hoge[0].nil?
    time_table_array << hoge
  end
end

result_table = Hash.new
time_table_array.each do |h|
  result_table["#{h[0]}"] = h[2]
end

pp result_table
