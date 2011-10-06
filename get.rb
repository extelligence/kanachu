# -*- coding: utf-8 -*-

require 'rubygems'
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

  def raw_html
    open(@url, 'User-Agent' => @user_agent).read.toutf8.gsub(/\r/, "\n")
  end

  def doc
    Nokogiri::HTML(raw_html)
  end
end

class Parser
  def self.exec(doc)
    start_hour = 5
    end_hour   = 26
    time_table_array = []
    result_table = Hash.new

    time_table_xpath = "/html/body/table[2]"
    html_time_table = doc.xpath(time_table_xpath)
    start_hour..end_hour.times do |i|
      hoge = html_time_table.xpath("tr[#{i - 1}]/td").text
      hoge.delete!("\n")
      hoge = hoge.split
      unless hoge[0].nil?
        time_table_array << hoge
      end
    end
    time_table_array.each do |h|
      result_table["#{h[0]}"] = h[2]
    end
    result_table
  end
end

if $0 == __FILE__
  url = "http://dia.kanachu.jp/bus/timetable?busstop=16064&pole=7&pole_seq=2&apply=2011/10/03&day=1"
  isehara = Crawler.new(url, USER_AGENT)
  pp Parser.exec(isehara.doc)
end
