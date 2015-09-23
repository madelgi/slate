require 'middleman-core/renderers/redcarpet'

module RedcarpetMods
  # make redcarpet parse markdown in various tags
  def block_html(raw_html)
    if (md = raw_html.match(/\<(.+?)\>(.*)\<(\/.+?)\>/m))
	    open_tag, content, close_tag = md.captures
      if (open_tag["aside"] && close_tag["aside"]) ||
         (open_tag["warning"] && close_tag["warning"])
        @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
	"<#{open_tag}>#{@markdown.render content}<#{close_tag}>"
      else
	raw_html
      end
    end
  end
end

Middleman::Renderers::MiddlemanRedcarpetHTML.send :include, RedcarpetMods
