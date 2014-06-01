require 'spec_helper'

describe(Jekyll::Gist::GistTag) do
  let(:doc) { doc_with_content(content) }
  let(:content)  { "{% gist #{gist} %}" }
  let(:output) do
    doc.content = content
    doc.output  = Jekyll::Renderer.new(doc.site, doc).run
  end

  context "simple gist" do
    let(:gist) { 358471 }

    it "produces the correct script tag" do
      expect(output).to match(/<script src="https:\/\/gist.github.com\/#{gist}.js">\s<\/script>/)
    end
  end

  context "private gist" do

    context "when valid" do
      let(:gist) { "mattr-/24081a1d93d2898ecf0f" }

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

    context "when invalid" do
      let(:gist) { "mattr-24081a1d93d2898ecf0f" }

      it "raises an error" do
        expect(->{ output }).to raise_error
      end
    end

  end

  context "no gist id present" do
    let(:gist) { "" }

    it "raises an error" do
      expect(->{ output }).to raise_error
    end
  end

end
