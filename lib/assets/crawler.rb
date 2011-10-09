# -*- coding: utf-8 -*-

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
