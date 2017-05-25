RSpec.describe MarkdownRubyDocumentation::ClassLevelComment do
  #=mark_doc
  # This is line 1
  # This is line 2
  #=mark_end
  class ToBeDocumented
    extend Forwardable
    def here_as_anchor

    end

    def_delegator :here_as_anchor, :abc

    NAME = 1
  end

  let(:interface) {
    {
      abc: {
        text:          "",
        method_object: MarkdownRubyDocumentation::Method.create("ToBeDocumented#abc", visibility: :native)
      },
      here_as_anchor: {
        text:          "",
        method_object: MarkdownRubyDocumentation::Method.create("ToBeDocumented#here_as_anchor", visibility: :native)
      },
      null_method: {
        text:          "",
        method_object: MarkdownRubyDocumentation::Method.create("ToBeDocumented::NAME", null_method: true)
      },
    }
  }

  describe "#call" do
    it do
      result = described_class.new(ToBeDocumented).call(interface)[:class_level_comment][:text]
      expect(result).to eq <<~COMMENT
       This is line 1
       This is line 2
      COMMENT
    end
  end
end
