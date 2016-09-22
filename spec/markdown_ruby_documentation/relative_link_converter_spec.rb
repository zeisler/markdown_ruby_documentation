RSpec.describe MarkdownRubyDocumentation::RelativeLinkConverter do
  subject {
    described_class.new(subject: double(name: "Hello::World"))
  }

  let(:output_object){
    double("output_object", relative_dir: "path")
  }

  before do
    MarkdownRubyDocumentation::Generate.output_object = output_object
  end

  let(:text) do
    %w{
      [link](https://github.com/zeisler/markdown_ruby_documentation/blob/master/path/hello/world.md#anchor)
      [link](https://github.com/zeisler/markdown_ruby_documentation/blob/master/path/hello/world.md)
      [link](https://github.com/zeisler/markdown_ruby_documentation/blob/master/path/goodbye/world.md#anchor)
      [link](https://github.com/zeisler/markdown_ruby_documentation/blob/master/path/hello/world.md#anchor)
    }.join("\n")
  end

  it do
    expect(subject.call(text).split("\n")).to eq(%w{
      [link](#anchor)
      [link](https://github.com/zeisler/markdown_ruby_documentation/blob/master/path/hello/world.md)
      [link](https://github.com/zeisler/markdown_ruby_documentation/blob/master/path/goodbye/world.md#anchor)
      [link](#anchor)
    })
  end
end
