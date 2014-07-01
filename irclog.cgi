#!/usr/bin/ruby
# -*- coding: utf-8 -*-
require 'cgi'
require 'date'
require_relative 'config'
require_relative 'view'

module Irclog
  class App
    def initialize
      cgi = CGI.new
      @view = View.new
      if !cgi["channel"].empty?
        @channel = cgi["channel"]
      end

      if !cgi["date"].empty?
        @date = Date.parse(cgi["date"])
      end

      if !cgi["keyword"].empty?
        @keyword = cgi["keyword"]
      end

      if !cgi["year"].empty?
        @year = cgi["year"]
      end

      if !cgi["json"].empty?
        @json = cgi["json"]
      end
    end

    def run
      ans = ""

      if @channel && !Config::CHANNEL_LIST.assoc(@channel)
        ans << html_http_header
        ans << @view.error
        puts ans
        return
      end

      if @channel && @keyword && @year
        ans << html_http_header
        ans << @view.search(@channel, @keyword, @year)
      elsif @channel && @date && @json == "true"
        ans << json_http_header
        ans << @view.json(@channel, @date)
      elsif @channel && @date
        ans << html_http_header
        ans << @view.daylog(@channel, @date, @keyword)
      elsif @channel
        ans << html_http_header
        ans << @view.channellog(@channel)
      else
        ans << html_http_header
        ans << @view.listlog
      end
      puts ans
    end

    def html_http_header
      return "Content-Type: text/html; charset=utf-8\n\n"
    end

    def json_http_header
      return "Content-Type: application/json; charset=utf-8\n\n"
    end
  end
end

app = Irclog::App.new
app.run
