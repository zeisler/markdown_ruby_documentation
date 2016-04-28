RSpec.describe MarkdownRubyDocumentation::Method do

  context "when is Kernel method" do
    before { allow(subject).to receive(:type).and_return(:instance_method) }
    before { allow(subject).to receive(:type_symbol).and_return("$") }
    subject { described_class.new("$puts") }
    it { expect(subject.context).to eq Kernel }
    it { expect(subject.name).to eq :puts }
    it { expect(subject.to_s).to eq "$puts" }
    it { expect(subject.context_name).to eq "Kernel" }
    it { expect(subject.to_proc.inspect).to eq("#<UnboundMethod: Kernel#puts>") }
    it { expect(described_class.create("#method_name")).to be_an_instance_of(MarkdownRubyDocumentation::InstanceMethod) }
  end

  context "when is custom context" do
    class FooBar
      def method_name
      end
    end

    before { allow(subject).to receive(:type_symbol).and_return("$") }
    before { allow(subject).to receive(:type).and_return(:instance_method) }
    subject { described_class.new("$method_name", context: FooBar) }
    it { expect(subject.context).to eq FooBar }
    it { expect(subject.to_proc.inspect).to eq "#<UnboundMethod: FooBar#method_name>" }
    it { expect(subject.name).to eq :method_name }
    it { expect(subject.to_s).to eq "$method_name" }
    it { expect(subject.context_name).to eq "FooBar" }
    it { expect(described_class.create("#method_name")).to be_an_instance_of(MarkdownRubyDocumentation::InstanceMethod) }
  end

  context "when is other" do
    class OtherContext
      def method_name
      end
    end

    before { allow(subject).to receive(:type_symbol).and_return("%") }
    before { allow(subject).to receive(:type).and_return(:instance_method) }
    subject { described_class.new("OtherContext%method_name", context: "OtherContext") }
    it { expect(subject.context).to eq OtherContext }
    it { expect(subject.to_proc.inspect).to eq "#<UnboundMethod: OtherContext#method_name>" }
    it { expect(subject.name).to eq :method_name }
    it { expect(subject.to_s).to eq "OtherContext%method_name" }
    it { expect(subject.context_name).to eq "OtherContext" }
    it { expect(described_class.create("OtherContext.method_name")).to be_an_instance_of(MarkdownRubyDocumentation::ClassMethod) }
  end

  context "nested context" do
    class OtherContext
      class NestedContext
        def method_name
        end
      end
    end

    before { allow(subject).to receive(:type_symbol).and_return("#") }
    before { allow(subject).to receive(:type).and_return(:instance_method) }
    subject { described_class.new("NestedContext#method_name", context: OtherContext) }
    it { expect(subject.context).to eq OtherContext::NestedContext }
    it { expect(subject.to_proc.inspect).to eq "#<UnboundMethod: OtherContext::NestedContext#method_name>" }
    it { expect(subject.name).to eq :method_name }
    it { expect(subject.context_name).to eq "NestedContext" }
    it { expect(subject.to_s).to eq "NestedContext#method_name" }
  end

  context "when formatted incorrectly" do
    it { expect { described_class.create("OtherContext::method_name") }.to raise_error(MarkdownRubyDocumentation::Method::InvalidMethodReference, "method_reference is formatted incorrectly: 'OtherContext::method_name'") }
    it { expect { described_class.create("if address.some_where?\n`DO_THING_VALUE => 0.95`\nend") }.to raise_error(MarkdownRubyDocumentation::Method::InvalidMethodReference, "method_reference is formatted incorrectly: 'if address.some_where?\n`DO_THING_VALUE => 0.95`\nend'") }
  end

  context "a null method" do
    subject { described_class.create("OtherContext", null_method: true) }
    it { expect(subject).to be_an_instance_of(MarkdownRubyDocumentation::NullMethod) }
    it { expect(subject.context).to eq OtherContext }
    it { expect(subject.name).to eq nil }
    it { expect(subject.context_name).to eq "OtherContext" }
    it { expect{subject.to_proc}.to raise_error("Not convertible to a proc") }
    it { expect(subject.to_s).to eq "OtherContext" }
  end
end
