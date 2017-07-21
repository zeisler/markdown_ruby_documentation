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
    @output = {}
    allow(output_object).to receive(:call) do |name:, text:|
      @output.merge!({ name => text })
    end
  end

  let(:output_object){ double("output_object", relative_dir: "spec") }

  it "saves a markdown file with generated docs" do
    described_class.run(subjects:    [{class: Namespace::DocumentMe, file_path: ""}],
                        load_path: "save_location",
                                 output_object: output_object)
    expect(@output["Namespace::DocumentMe"]).to eq <<~MD
      # Document Me < [Super Thing](https://github.com/zeisler/markdown_ruby_documentation/blob/#{MarkdownRubyDocumentation::GitHubProject.branch}/spec/namespace/super_thing.md)
      Descendants: [Other Thing](https://github.com/zeisler/markdown_ruby_documentation/blob/#{MarkdownRubyDocumentation::GitHubProject.branch}/spec/namespace/other_thing.md)

      ## The Sum Of A And B
      This is an important part of the logic
      ```ruby
      2 + 4
      ```
      ```javascript
      {"abc":"123","xyz":"890"}
      ```

      [show on github](https://github.com/zeisler/markdown_ruby_documentation/blob/#{MarkdownRubyDocumentation::GitHubProject.branch}/spec/markdown_ruby_documentation/generate_spec.rb#L17)

    MD
  end

  it "structure" do
    pages = described_class.run(subjects: [{class: Namespace::DocumentMe, file_path: ""}], load_path: "load_path", output_object: output_object)
    expect(pages).to eq({ "Namespace" => { "DocumentMe" => pages["Namespace"]["DocumentMe"] } })
  end
end
