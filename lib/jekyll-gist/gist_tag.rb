# frozen_string_literal: true

require "cgi"
require "net/http"
require "octokit"

Net::OpenTimeout = Class.new(RuntimeError) unless Net.const_defined?(:OpenTimeout)
Net::ReadTimeout = Class.new(RuntimeError) unless Net.const_defined?(:ReadTimeout)

module Jekyll
  module Gist
    class GistTag < Liquid::Tag
      def self.client
        @client ||= Octokit::Client.new :access_token => ENV["JEKYLL_GITHUB_TOKEN"]
      end

      def render(context)
        @encoding = context.registers[:site].config["encoding"] || "utf-8"
        @settings = context.registers[:site].config["gist"]
        if (tag_contents = determine_arguments(@markup.strip))
          gist_id  = tag_contents[0]
          filename = tag_contents[1]
          gist_id  = context[gist_id]  if context.key?(gist_id)
          filename = context[filename] if context.key?(filename)

          noscript_tag = gist_noscript_tag(gist_id, filename)
          script_tag   = gist_script_tag(gist_id, filename)

          "#{noscript_tag}#{script_tag}"
        else
          raise ArgumentError, <<~ERROR
            Syntax error in tag 'gist' while parsing the following markup:

              '{% #{raw.strip} %}'

            Valid syntax:
              {% gist user/1234567 %}
              {% gist user/1234567 foo.js %}
              {% gist 28949e1d5ee2273f9fd3 %}
              {% gist 28949e1d5ee2273f9fd3 best.md %}

          ERROR
        end
      end

      private

      def determine_arguments(input)
        matched = input.match(%r!\A([\S]+|.*(?=\/).+)\s?(\S*)\Z!)
        [matched[1].strip, matched[2].strip] if matched && matched.length >= 3
      end

      def gist_script_tag(gist_id, filename = nil)
        url = "https://gist.github.com/#{gist_id}.js"
        url = "#{url}?file=#{filename}" unless filename.to_s.empty?

        "<script src=\"#{url}\" loading="lazy"> </script>"
      end

      def gist_noscript_tag(gist_id, filename = nil)
        return if @settings && @settings["noscript"] == false

        code = fetch_raw_code(gist_id, filename)
        if code
          code = code.force_encoding(@encoding)
          code = CGI.escapeHTML(code).gsub("'", "&#39;")

          "<noscript><pre>#{code}</pre></noscript>"
        else
          Jekyll.logger.warn "Warning:", "The <noscript> tag for your gist #{gist_id}"
          Jekyll.logger.warn "", "could not be generated. This will affect users who do"
          Jekyll.logger.warn "", "not have JavaScript enabled in their browsers."
        end
      end

      def fetch_raw_code(gist_id, filename = nil)
        return code_from_api(gist_id, filename) if ENV["JEKYLL_GITHUB_TOKEN"]

        url = "https://gist.githubusercontent.com/#{gist_id}/raw"
        url = "#{url}/#{filename}" unless filename.to_s.empty?
        uri = URI(url)

        Net::HTTP.start(uri.host, uri.port,
                        :use_ssl => uri.scheme == "https",
                        :read_timeout => 3, :open_timeout => 3) do |http|
          request = Net::HTTP::Get.new uri.to_s
          response = http.request(request)
          response.body
        end
      rescue SocketError, Net::HTTPError, Net::OpenTimeout, Net::ReadTimeout, TimeoutError
        nil
      end

      def code_from_api(gist_id, filename = nil)
        gist = GistTag.client.gist gist_id
        file = if filename.to_s.empty?
                 # No file specified, return the value of the first key/value pair
                 gist.files.first[1]
               else
                 # .files is a hash of :"filename.extension" => data pairs
                 # Rather than using to_sym on arbitrary user input,
                 # Find our file by calling to_s on the keys
                 match = gist.files.find { |name, _data| name.to_s == filename }
                 match[1] if match
               end

        file[:content] if file
      end
    end
  end
end

Liquid::Template.register_tag("gist", Jekyll::Gist::GistTag)
