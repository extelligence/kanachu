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

class Timetables
  #
  # ■ユーザーの利用路線について
  # ▼22:05以前の場合、どちらかに乗車する。
  #   平86             [枝大島入口下車] 伊勢原駅南口行(大田経由)
  #   平68             [枝大島入口下車] 愛甲石田駅行
  # ▼22:05以降の場合、どれかに乗車する。
  #   平63             [田村車庫下車]   田村車庫行(横内経由)
  #   平65             [田村車庫下車]   田村車庫行(大島経由)
  #   平67             [田村車庫下車]   田村車庫行(神明経由)
  #   平51 平52 平60   [田村車庫下車]   田村車庫行(旧道経由)
  #   平97             [大島住宅下車]   伊勢原駅南口行(平間・大島経由) ※19:45以降ないみたい。
  #
  # URLパラメータ仕様
  # [pole]     行き先
  # [pole_seq] 経由
  # [day]      平日:1 土曜:2 休日:3
  KANACHU_TIMETABLE_URL = [
    {"url" => "http://dia.kanachu.jp/bus/timetable?busstop=16064&pole=4&pole_seq=2&apply=2011/10/03&day=1", "name" => "伊勢原駅南口行(大田経由)"},
    {"url" => "http://dia.kanachu.jp/bus/timetable?busstop=16064&pole=4&pole_seq=7&apply=2011/10/03&day=1", "name" => "愛甲石田駅行"},
    {"url" => "http://dia.kanachu.jp/bus/timetable?busstop=16064&pole=4&pole_seq=3&apply=2011/10/03&day=1", "name" => "田村車庫行(横内経由)"},
    {"url" => "http://dia.kanachu.jp/bus/timetable?busstop=16064&pole=4&pole_seq=4&apply=2011/10/03&day=1", "name" => "田村車庫行(大島経由)"},
    {"url" => "http://dia.kanachu.jp/bus/timetable?busstop=16064&pole=4&pole_seq=5&apply=2011/10/03&day=1", "name" => "田村車庫行(神明経由)"},
    {"url" => "http://dia.kanachu.jp/bus/timetable?busstop=16064&pole=5&pole_seq=2&apply=2011/10/03&day=1", "name" => "田村車庫行(旧道経由)"},
    {"url" => "http://dia.kanachu.jp/bus/timetable?busstop=16064&pole=4&pole_seq=6&apply=2011/10/03&day=1", "name" => "伊勢原駅南口行(平間・大島経由)"}
  ]


  def self.all
    timetables = []
    KANACHU_TIMETABLE_URL.each do |t|
      html = Crawler.new(t['url'], USER_AGENT)
      timetables << {"name" => t['name'], "time" => Parser.to_array(html.doc)}
    end
    timetables
  end

  def self.get_bus_now?
    recommand_time_table, tmp = [], []

    all.each do |h|
      h["time"].select{|x| x[0] == now_hour}.each do |m|
        recommand_time_table << {"name" => h["name"], "time" => m}
      end
    end

    if recommand_time_table.empty?
      recommand_time_table << {"name" => "この時間のバスはないよ！", "time" => ["XX", "XX"]}
    else
      recommand_time_table.each do |x|
        tmp << [x['time'].join(), x]
      end
      recommand_time_table.clear
      tmp.sort.each do |x|
        recommand_time_table << x[1]
      end
      recommand_time_table
    end
  end
end

def now_hour
  Time.now.strftime("%H")
end

if $0 == __FILE__
  puts '=' * 80
  puts "現在の時間: #{Time.now.strftime("%H:%M")}"
  print "\n"
  puts Timetables.get_bus_now?
  puts '=' * 80
end
