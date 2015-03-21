require 'spec_helper'

describe(Jekyll::Gist::GistTag) do
  let(:doc) do
    doc_with_content(content).tap { |doc| doc.data['gist_id'] = global_gist_id if respond_to? :global_gist_id }
  end
  let(:content)  { "{% gist #{gist} %}" }
  let(:output) do
    doc.content = content
    doc.output  = Jekyll::Renderer.new(doc.site, doc).run
  end


  context "valid gist" do
    context "with user prefix" do
      let(:gist) { "mattr-/24081a1d93d2898ecf0f" }

      it "produces the correct script tag" do
        expect(output).to match(/<script src="https:\/\/gist.github.com\/#{gist}.js">\s<\/script>/)
      end
    end

    context "without user prefix" do
      let(:gist) { "28949e1d5ee2273f9fd3" }

      it "produces the correct script tag" do
        expect(output).to match(/<script src="https:\/\/gist.github.com\/#{gist}.js">\s<\/script>/)
      end
    end

    context "classic Gist id style" do
      let(:gist) { "1234321" }

      it "produces the correct script tag" do
        expect(output).to match(/<script src="https:\/\/gist.github.com\/#{gist}.js">\s<\/script>/)
      end
    end

    context "with file specified" do
      let(:gist)     { "mattr-/24081a1d93d2898ecf0f" }
      let(:filename) { "myfile.ext" }
      let(:content)  { "{% gist #{gist} #{filename} %}" }

      it "produces the correct script tag" do
        expect(output).to match(/<script src="https:\/\/gist.github.com\/#{gist}.js\?file=#{filename}">\s<\/script>/)
      end
    end
  end


  context "invalid gist" do

    context "no gist id present" do
      let(:gist) { "" }

      it "raises an error" do
        expect(->{ output }).to raise_error
      end
    end

  end

  context "A post with gist_id in front matter" do
    let(:global_gist_id) { 'global-gist-id' }
    let(:local_gist_id) { 'local-gist-id' }
    let(:filename) { 'my-file.md' }
    context "with a gist string that has another gist_id" do
      let(:gist) { "#{local_gist_id} #{filename}" }
      it 'will use the local gist id in the url' do
        expect(output).to match(/<script src="https:\/\/gist.github.com\/#{local_gist_id}.js\?file=#{filename}">\s<\/script>/)
      end
    end
    context "with an empty gist_id in the gist string" do
      let(:gist) { filename }
      it 'will use the gist_id from the front matter' do
        expect(output).to match(/<script src="https:\/\/gist.github.com\/#{global_gist_id}.js\?file=#{filename}">\s<\/script>/)
      end
    end
  end

end
