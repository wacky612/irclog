# -*- coding: utf-8 -*-
require 'erb'
require 'date'
require 'time'
require 'json'
require_relative 'config'
require_relative 'log'

module Irclog
  class View
    WDAYS = ["日", "月", "火", "水", "木", "金", "土"]

    def initialize
      @log = Log.new
    end

    def daylog(channel, date, keyword)
      daylogs = []
      if @log.exist?(channel, date)
        daylog = {}
        logs = @log.filter(@log.parse(channel, date), Config::LOG_FILTER)
        if !logs.empty?
          logs = @log.convert_logs(logs)
          logs = @log.mark_keyword(logs, keyword) if keyword
          daylog[:log] = logs
          daylog[:date] = date
          daylogs << daylog
        end
      end
      channel_array = Config::CHANNEL_LIST.assoc(channel)
      body = page_header("#{channel_array.last} - " + date.strftime("%Y/%m/%d") +
                         " (#{WDAYS[date.wday]})")
      body << search_form(channel)
      body << daylink(channel, date)
      if !daylogs.empty?
        body << log(daylogs)
        body << daylink(channel, date)
      else
        body << "この日は発言がありませんでした。<br>"
      end
      return html(body)
    end

    def listlog
      body = page_header(Config::CGI_NAME)
      channel_logs = []
      channels = []
      Config::CHANNEL_LIST.each do |array|
        channels << array[0]
      end
      channels.each do |channel|
        channel_log = {}
        daylogs = []
        today = Date.today
        logs_length = 0
        for d in 0..30 do
          if @log.exist?(channel, today - d)
            daylog = {}
            logs = @log.tail(@log.filter(@log.parse(channel, today - d),
                                         Config::LOG_FILTER),
                             Config::LIST_LOG_LENGTH - logs_length)
            if !logs.empty?
              daylog[:log] = @log.convert_logs(logs)
              daylog[:date] = today - d
              daylogs.insert(0, daylog)
              logs_length = logs_length + daylog[:log].length
            end
          end
          break if logs_length == Config::LIST_LOG_LENGTH
        end

        if !daylogs.empty?
          channel_log[:date] = daylogs.last[:date]
          channel_log[:time] = daylogs.last[:log].last[:time]
          channel_log[:text] = log_header(channel, daylogs.last[:date],
                                          daylogs.last[:log].last[:time])
          channel_log[:text] << search_form(channel)
          channel_log[:text] << log(daylogs)
        else
          channel_log[:date] = today - 31
          channel_log[:time] = Time.parse("00:00:00")
          channel_log[:text] = log_header(channel, today - 31, nil)
          channel_log[:text] << search_form(channel)
          channel_log[:text] << "このチャンネルは30日間発言がありませんでした。<br>"
        end
        channel_logs << channel_log
      end

      channel_logs.sort! do |a, b|
        if a[:date] == b[:date]
          b[:time] <=> a[:time]
        else
          b[:date] <=> a[:date]
        end
      end

      channel_logs.each do |channel_log|
        body << channel_log[:text]
      end

      return html(body)
    end

    def json(channel, date)
      json = ""
      if @log.exist?(channel, date)
        json = JSON.generate(@log.parse(channel, date))
      end
      return json
    end

    def search(channel, keyword, year)
      body = page_header("#{Config::CHANNEL_LIST.assoc(channel).last}の検索結果 (keyword = #{keyword}, year = #{year})")
      body << search_form(channel, year)
      body << search_result(channel, keyword, year)
      return html(body)
    end

    def error()
      body = page_header("そのようなチャンネルは存在しません")
      return html(body)
    end

    private

    def erb(filename)
      ERB.new(File.read("erb/#{filename}", :encoding => Encoding::UTF_8),
              nil, '%')
    end

    def html(body)
      title = Config::CGI_NAME
      return erb("html.erb").result(binding)
    end

    def log(daylogs)
      return erb("log.erb").result(binding)
    end

    def log_header(channel, date, time)
      channel_array = Config::CHANNEL_LIST.assoc(channel)
      channel_name = channel_array.last
      return erb("log_header.erb").result(binding)
    end

    def daylink(channel, date)
      return erb("daylink.erb").result(binding)
    end

    def page_header(text)
      return erb("page_header.erb").result(binding)
    end

    def search_result(channel, keyword, year)
      date_array = @log.grep(channel, keyword, year)
      return erb("search_result.erb").result(binding)
    end

    def search_form(selected_channel, selected_year=nil)
      selected_year ||= Date.today.year.to_s
      channel_list = Config::CHANNEL_LIST
      return erb("search_form.erb").result(binding)
    end
  end
end
