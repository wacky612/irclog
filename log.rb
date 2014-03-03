# -*- coding: utf-8 -*-
require 'date'
require 'uri'
require 'nkf'
require 'cgi'
require 'fileutils'
require_relative 'config'
require_relative 'convert_control_char'

module Irclog
  class Log

    def parse(channel, date)
      logs = []
      date_str = date.strftime("%Y.%m.%d")
      log_text = File.read("#{Config::LOG_DIR}/#{channel}/#{date_str}.txt")
      log_text.force_encoding(NKF.guess(log_text))
      # NKFが\cOを消してしまうのでいったん別の文字にする
      log_text = NKF.nkf("-w", log_text.gsub(/\cO/, "\cZ")).gsub(/\cZ/, "\cO")
      log_text.each_line do |line|
        log = {}
        log[:time] = Time.parse(date_str + " " + line[0..7])
        case line[9..-1]
        when /^<\S+:(\S+?)> \cAACTION (.*)\cA$/
          log[:type] = "ACTION"
          log[:nick] = $1
          log[:content] = $2
        when /^(<|>)\S+:(\S+?)(>|<) (.*)$/
          log[:type] = "PRIVMSG"
          log[:nick] = $2
          log[:content] = $4
        when /^(\(|\))\S+:(\S+?)(\)|\() (.*)$/
          log[:type] = "NOTICE"
          log[:nick] = $2
          log[:content] = $4
        when /^\+ (\S+) \(\S+\) to \S+$/
          log[:type] = "JOIN"
          log[:nick] = $1
        when /^! (\S+) \(Quit: (.+)\)$/
          log[:type] = "PART"
          log[:nick] = $1
          log[:content] = $2
        when /^My nick is changed \((\S+) -> (\S+)\)$/, /^(\S+) -> (\S+)$/
          log[:type] = "NICK"
          log[:nick] = $1
          log[:new_nick] = $2
        when /^Mode by (\S+): \S+ \+o (\S+)$/
          log[:type] = "OP"
          log[:nick] = $1
          log[:target] = $2
        when /^Mode by (\S+): \S+ -o (\S+)$/
          log[:type] = "DEOP"
          log[:nick] = $1
          log[:target] = $2
        when /^- (\S+) by (\S+) from \S+ \((.+)\)$/
          log[:type] = "KICK"
          log[:target] = $1
          log[:nick] = $2
          log[:reason] = $3
        when /^Topic of channel \S+ by (\S+?): (.+)$/
          log[:type] = "TOPIC"
          log[:nick] = $1
          log[:content] = $2
        else
          next
        end
        logs << log
      end
      return logs
    end

    def convert_logs(logs)
      logs.each do |log|
        if log[:content]
          text = CGI.escapeHTML(log[:content])
          text = ConvertControlChar.new(text).convert
          text = text.gsub(URI.regexp(["http", "https"]), "<a target=\"_blank\" href=\"\\0\">\\0</a>")
          log[:content] = text
        end
      end
      return logs
    end

    def mark_keyword(logs, keyword)
      logs.each do |log|
        if log[:content]
          log[:content].gsub!(Regexp.new(keyword), "<mark>\\0</mark>")
          # <a href...>内の <mark> を取り除く
          log[:content].gsub!(/(<a.*(<mark>(.*)<\/mark>).*\">)(.*<\/a>)/) do |url|
            msg = $4
            link = $1.gsub($2, $3)
            url = link + msg
          end
        end
      end
      return logs
    end

    def filter(logs, filter_array)
      logs.delete_if do |log|
        !filter_array.include?(log[:type])
      end
      return logs
    end

    def tail(logs, n)
      if logs.size() > n
        return logs[-n..-1]
      else
        return logs
      end
    end

    def exist?(channel, date=nil)
      if date
        return File.exist?("#{Config::LOG_DIR}/#{channel}/#{date.strftime("%Y.%m.%d")}.txt")
      else
        return File.exist?("#{Config::LOG_DIR}/#{channel}")
      end
    end

    def grep(channel, keyword, year)
      ans = []
      privmsg = /\d\d:\d\d:\d\d (<|>).+:\*\.jp:.+?(>|<) (.*)/
      notice = /\d\d:\d\d:\d\d (\(|\)).+:\*\.jp:.+?(\)|\() (.*)/
      Dir.chdir("#{Config::LOG_DIR}/#{channel}") do
        Dir.glob("#{year}.*.txt") do |file|
          log = File.read(file)
          log = NKF.nkf("-w", log)
          log.each_line do |line|
            if line =~ privmsg || line =~ notice
              if $3 =~ Regexp.new(keyword)
                ans << file.scan(/\d{4}.\d\d.\d\d/)[0]
                break
              end
            end
          end
        end
      end
      return ans.sort.reverse
    end

  end
end

