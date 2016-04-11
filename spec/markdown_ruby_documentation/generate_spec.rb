RSpec.describe MarkdownRubyDocumentation::Generate do
  module Namespace
    class SuperThing
    end

    class DocumentMe < SuperThing

      #=mark_doc
      # This is an important part of the logic
      # ```ruby
      # <%= print_method_source("#a") %> + <%= print_method_source("#b") %>
      # ```
      # ```javascript
      # <%= eval_method("Resource#table").to_json %>
      # ```
      #=mark_end
      def the_sum_of_a_and_b
        a + b
      end

      private

      def a
        2
      end

      def b
        4
      end

    end

    class OtherThing < DocumentMe
    end
  end

  class Resource
    def table
      { "abc" => "123",
        "xyz" => "890" }
    end
  end

  class NullMethodPipe
    def initialize(*args)
    end

    def call(args)
      args
    end
  end

  before do
    stub_const("MarkdownRubyDocumentation::GitHubLink", NullMethodPipe)
    expect_any_instance_of(NullMethodPipe)
      .to receive(:call)
            .with({ :the_sum_of_a_and_b => "This is an important part of the logic\n```ruby\n2 + 4\n```\n```javascript\n{\"abc\":\"123\",\"xyz\":\"890\"}\n```\n" })
            .and_call_original
  end

  it "saves a markdown file with generated docs" do
    output = {}
    described_class.run(subjects:    [Namespace::DocumentMe],
                                 output_proc: -> (name:, text:) { output.merge!({ name => text }) })
    expect(output["Namespace::DocumentMe"]).to eq <<~MD
      # Document Me < [Super Thing](../namespace/super_thing.md)
      Descendants: [Other Thing](../namespace/other_thing.md)

      ## The Sum Of A And B
      This is an important part of the logic
      ```ruby
      2 + 4
      ```
      ```javascript
      {"abc":"123","xyz":"890"}
      ```

    MD
  end

  it "structure" do
    pages = described_class.run(subjects: [Namespace::DocumentMe])
    expect(pages).to eq({ "Namespace" => { "DocumentMe" => pages["Namespace"]["DocumentMe"] } })
  end
end
