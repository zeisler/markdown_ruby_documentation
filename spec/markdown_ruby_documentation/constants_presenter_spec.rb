RSpec.describe MarkdownRubyDocumentation::ConstantsPresenter do
  class SomeClassWithSomeConstants
    CONSTANT_NUM    = 10_000
    CONSTANT_STRING = "hello"
    MY_MUTEX = Mutex.new
  end

  describe "#call" do
    subject { described_class.new(SomeClassWithSomeConstants) }

    it do
      result = subject.call({ method_name_does_not_matter: { text: "", method_object: nil } })
      expect(result).to eq({
                             method_name_does_not_matter: { text:          "",
                                                            method_object: nil },
                             CONSTANT_NUM:                { text:          "10,000",
                                                            method_object: MarkdownRubyDocumentation::NullMethod.new("SomeClassWithSomeConstants::CONSTANT_NUM") },
                             CONSTANT_STRING:             { text:          '"hello"',
                                                            method_object: MarkdownRubyDocumentation::NullMethod.new("SomeClassWithSomeConstants::CONSTANT_STRING") }
                           })
    end
  end
end
