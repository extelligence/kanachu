# -*- coding: utf-8 -*-

require 'pp'
require 'kconv'
require 'net/http'
require 'nokogiri'
require 'open-uri'
require 'crawler'
require 'parser'

USER_AGENT = 'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0)'
RESULT_TIMETABLE_NUM = 10

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
    {"url" => "http://dia.kanachu.jp/bus/timetable?busstop=16064&pole=4&pole_seq=2&apply=2011/10/16&day=1", "name" => "伊勢原駅南口行", "via" => "大田経由", "boarding" => "4"},
    {"url" => "http://dia.kanachu.jp/bus/timetable?busstop=16064&pole=4&pole_seq=7&apply=2011/10/16&day=1", "name" => "愛甲石田駅行", "via" => "", "boarding" => "4"},
    {"url" => "http://dia.kanachu.jp/bus/timetable?busstop=16064&pole=4&pole_seq=3&apply=2011/10/16&day=1", "name" => "田村車庫行", "via" => "横内経由", "boarding" => "4"},
    {"url" => "http://dia.kanachu.jp/bus/timetable?busstop=16064&pole=4&pole_seq=4&apply=2011/10/16&day=1", "name" => "田村車庫行", "via" => "大島経由", "boarding" => "4"},
    {"url" => "http://dia.kanachu.jp/bus/timetable?busstop=16064&pole=4&pole_seq=5&apply=2011/10/16&day=1", "name" => "田村車庫行", "via" => "神明経由", "boarding" => "4"},
    {"url" => "http://dia.kanachu.jp/bus/timetable?busstop=16064&pole=5&pole_seq=2&apply=2011/10/16&day=1", "name" => "田村車庫行", "via" => "旧道経由", "boarding" => "5"},
    {"url" => "http://dia.kanachu.jp/bus/timetable?busstop=16064&pole=4&pole_seq=6&apply=2011/10/16&day=1", "name" => "伊勢原駅南口行", "via" => "平間・大島経由", "boarding" => "4"}
  ]


  def self.all
    timetables = []
    KANACHU_TIMETABLE_URL.each do |t|
      html = Crawler.new(t['url'], USER_AGENT)
      timetables << {"name" => t['name'], "time" => Parser.to_array(html.doc), "boarding" => t['boarding'], "via" => t['via']}
    end
    timetables
  end

  def self.get_bus_now(now_hour_minutes)
    recommand_time_table, tmp = [], []

    all.each do |h|
      h["time"].select{|x| x.to_i >= now_hour_minutes.to_i}.each do |m|
        recommand_time_table << {"name" => h["name"], "time" => m, "boarding" => h['boarding'], "via" => h['via']}
      end
    end

    if recommand_time_table.empty?
      recommand_time_table << {"name" => "帰りのバスはありません", "time" => ["--", "--"], "boarding" => "-", "via" => ""}
    else
      recommand_time_table.each do |x|
        tmp << [x['time'], x]
      end
      recommand_time_table.clear
      tmp.sort_by{|x| x[0].to_i}.each do |x|
        recommand_time_table << x[1]
      end

      # 24時台の場合の対応
      # TODO: 現在取得できていない。要修正。
      now_hour = now_hour_minutes.unpack("a2" * (now_hour_minutes.size / 2))
      if now_hour[0] == "00"
        all.each do |h|
          h["time"].select{|x| x[0].to_i == 24}.each do |m|
            recommand_time_table.unshift({"name" => h["name"], "time" => m, "boarding" => h['boarding'], "via" => h["via"]})
          end
        end
      end

      recommand_time_table[0..(RESULT_TIMETABLE_NUM - 1)]
    end
  end
end

if $0 == __FILE__
  puts '=' * 80
  puts "現在の時間: #{Time.now.strftime("%H:%M")}"
  print "\n"
  puts Timetables.get_bus_now(Time.now.strftime("%H%M"))
  puts '=' * 80
end
