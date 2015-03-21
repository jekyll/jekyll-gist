module Jekyll
  module Gist
    class GistTag < Liquid::Tag

      def render(context)
        if tag_contents = determine_arguments(@markup.strip)
          global_gist_id = context.registers[:page]['gist_id']
          gist_id, filename = tag_contents[0], tag_contents[1]
          if global_gist_id && tag_contents[1].empty?
            gist_id, filename = global_gist_id, tag_contents[0]
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
        if filename.empty?
          "<script src=\"https://gist.github.com/#{gist_id}.js\"> </script>"
        else
          "<script src=\"https://gist.github.com/#{gist_id}.js?file=#{filename}\"> </script>"
        end
      end

    end
  end
end

Liquid::Template.register_tag('gist', Jekyll::Gist::GistTag)
