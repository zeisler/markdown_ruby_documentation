RSpec.describe MarkdownRubyDocumentation::Method do

  context "when is ruby_class" do
    before { allow(subject).to receive(:type_symbol).and_return("$") }
    subject { described_class.new("$method_name") }
    it { expect(subject.context).to eq :ruby_class }
    it { expect(subject.name).to eq :method_name }
    it { expect(subject.to_s).to eq "$method_name" }
    it { expect(described_class.create("#method_name")).to be_an_instance_of(MarkdownRubyDocumentation::InstanceMethod) }
  end

  context "when is other" do
    before { allow(subject).to receive(:type_symbol).and_return("%") }
    subject { described_class.new("OtherContext%method_name") }
    it { expect(subject.context).to eq :OtherContext }
    it { expect(subject.name).to eq :method_name }
    it { expect(subject.to_s).to eq "OtherContext%method_name" }
    it { expect(described_class.create("OtherContext.method_name")).to be_an_instance_of(MarkdownRubyDocumentation::ClassMethod) }
  end

  context "when formatted incorrectly" do
    it { expect { described_class.create("OtherContext::method_name") }.to raise_error(ArgumentError, "method_reference is formatted incorrectly: 'OtherContext::method_name'") }
  end

  context "a null method" do
    subject { described_class.create("OtherContext", null_method: true) }
    it { expect(subject).to be_an_instance_of(MarkdownRubyDocumentation::NullMethod) }
    it { expect(subject.context).to eq :OtherContext }
    it { expect(subject.name).to eq nil }
    it { expect(subject.to_s).to eq "OtherContext" }
  end
end
