module Jekyll
  module Gist
    class GistTag < Liquid::Tag

      def render(context)
        if tag_contents = determine_arguments(@markup.strip)
          gist_id, filename = tag_contents[0], tag_contents[1]
          if context.has_key?(gist_id)
            gist_id = context[gist_id]
          end
          if context.has_key?(filename)
            filename = context[filename]
          end
          gist_script_tag(gist_id, filename)
        else
          raise ArgumentError.new <<-eos
  Syntax error in tag 'gist' while parsing the following markup:

    #{@markup}

  Valid syntax:
    {% gist user/1234567 %}
    {% gist user/1234567 foo.js %}
    {% gist 28949e1d5ee2273f9fd3 %}
    {% gist 28949e1d5ee2273f9fd3 best.md %}
  eos
        end
      end

      private

      def determine_arguments(input)
        matched = input.match(/\A([\S]+|.*(?=\/).+)\s?(\S*)\Z/)
        [matched[1].strip, matched[2].strip] if matched && matched.length >= 3
      end

      def gist_script_tag(gist_id, filename = nil)
        "<script type='text/javascript'>
          (function(gistId, filename) {
            var callbackName  = 'gist'+gistId,
              uri             = '//gist.github.com/'+gistId+'.json?callback='+callbackName;
            if (filename !== null && filename !== '') {
              uri += '&file='+filename;
            }
            window[callbackName] = function (gistData) {
              delete window[callbackName];
              var html = '<link rel=\"stylesheet\" href=\"'+gistData.stylesheet+'\"></link>';
              html += gistData.div;
              element = document.getElementById('gist'+gistId);
              if (typeof(element) !== 'undefined') {
                element.innerHTML = html; 
              }
              script.parentNode.removeChild(script);
            };
            var script = document.createElement('script');
            script.setAttribute('src', uri);
            document.body.appendChild(script);
          }('#{gist_id}', '#{filename}'));
        </script><div id=\"gist#{gist_id}\"><a href=\"//gist.github.com/#{gist_id}\">#{gist_id}</a></div>"
      end

    end
  end
end

Liquid::Template.register_tag('gist', Jekyll::Gist::GistTag)

