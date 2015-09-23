require 'middleman-core/renderers/redcarpet'

# extends the md syntax w/ some postprocessing rules
class Middleman::Renderers::MiddlemanRedcarpetHTML
  def normal_text(text)
    wrap_admonitions(text)
  end

  def wrap_admonitions(text)
    text.gsub! /\[[ ]*([a-z]*)[ ]*:(.*)\]/ do
      "<aside class=\"#{$1}\">#{$2}</aside>"
    end
    text
  end
end
