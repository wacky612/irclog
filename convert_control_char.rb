module Irclog
  module Tag
    BOLD = "<span class=\"bold\">"
    U = "<span class=\"u\">"
    COLOR = [
             "white", "black", "darkblue", "darkgreen", "red", "darkred", "darkpurple", "orange",
             "yellow", "green", "darkcyan", "cyan", "blue", "purple", "darkgray", "gray"
            ]
  end

  class ConvertControlChar
    def initialize(text)
      @text = text
      @tags = Tags.new
    end

    def convert
      ans = ""
      i = 0

      while i = @text.index(/\cB|\c_|\cO|\cC|\cV|\cR/)
        ans << @text[0...i]
        case @text[i]
        when "\cC"
          if @text[(i+1)..(i+5)] =~ /^(\d{1,2}),(\d{1,2})/
            fg_index = $1.to_i % Tag::COLOR.length
            bg_index = $2.to_i % Tag::COLOR.length
            ans << @tags.color(fg_index, bg_index)
            @text = @text[(i+2+$1.length+$2.length)..-1]
            next
          elsif @text[(i+1)..(i+2)] =~ /^(\d{1,2})/
            fg_index = $1.to_i % Tag::COLOR.length
            ans << @tags.color(fg_index)
            @text = @text[(i+1+$1.length)..-1]
            next
          else
            ans << @tags.reset_color
          end
        when "\cV", "\cR"
          ans << @tags.reverse_color
        when "\cB"
          ans << @tags.toggle_bold
        when "\c_"
          ans << @tags.toggle_u
        when "\cO"
          ans << @tags.clear
        end
        @text = @text[(i+1)..-1]
      end
      ans << @text
      return ans
    end
  end

  class Tags
    def initialize
      @tags = []
      @fg_index = 1
      @bg_index = 0
    end

    def toggle_bold
      if @tags.include?(Tag::BOLD)
        return untag(Tag::BOLD)
      else
        return append(Tag::BOLD)
      end
    end

    def toggle_u
      if @tags.include?(Tag::U)
        return untag(Tag::U)
      else
        return append(Tag::U)
      end
    end

    def clear
      tag_num = @tags.length
      @tags = []
      @fg_index = 1
      @bg_index = 0
      return "</span>" * tag_num
    end

    def color(fg_index, bg_index = nil)
      @fg_index = fg_index
      @bg_index = bg_index if bg_index
      if @tags.include?(Tag::U)
        ans = toggle_u
        ans << append("<span class=\"#{Tag::COLOR[@fg_index]} bg#{Tag::COLOR[@bg_index]}\">")
        ans << toggle_u
        return ans
      else
        return append("<span class=\"#{Tag::COLOR[@fg_index]} bg#{Tag::COLOR[@bg_index]}\">")
      end
    end

    def reset_color
      return color(1, 0)
    end

    def reverse_color
      return color(@bg_index, @fg_index)
    end

    private

    def append(tag)
      @tags << (tag)
      return tag
    end

    def untag(tag)
      tag_index = @tags.index(tag)
      ans = "</span>" * (@tags.length - tag_index) + @tags[(tag_index + 1)..-1].join
      @tags.delete_at(tag_index)
      return ans
    end
  end
end
