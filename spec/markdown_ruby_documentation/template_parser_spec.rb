RSpec.describe MarkdownRubyDocumentation::TemplateParser do
  describe "#to_hash" do
    context "COMMENT_REF:" do
      let!(:ruby_class) {
        class Test
          # Hello
          def method1
          end

          #=mark_doc
          # This method does stuff
          # <%= print_mark_doc_from "#method3" %>
          #=mark_end
          def method2
          end

          #=mark_doc
          # <%= print_raw_comment "#method1" -%>
          #=mark_end
          def method3
          end

          #=mark_doc
          # <%= print_mark_doc_from "Test2#method5" %>
          # <%= print_raw_comment "#method1" -%>
          #=mark_end
          def method4
          end
        end

        class Test2
          #=mark_doc
          # Goodbye
          #=mark_end
          def method5
          end
        end
      }

      it "complies comments references" do
        result = described_class.new(Test, [:method1, :method2, :method4]).to_hash
        expect(convert_method_hash(result)).to eq({ method1: "", method2: "This method does stuff\nHello\n\n", :method4 => "Goodbye\n\nHello\n" })
      end
    end

    context "eval_method:" do
      let!(:ruby_class) {
        class Test
          def self.method1
            { key: "fun" }
          end

          #=mark_doc
          # <%= eval_method ".method1" %>
          #=mark_end
          def method2
          end

          #=mark_doc
          # <%= eval_method("Test2.method5") %>
          #=mark_end
          def method3
          end

          #=mark_doc
          # <%= print_method_source("Test2#method6") %>
          # Whatever!
          #=mark_end
          def method4
          end

          #=mark_doc
          # <%= eval_method("Test2#method6") %>
          #=mark_end
          def method5
            "im 5"
          end

          #=mark_doc
          # <%= eval_method("#method5") %>
          #=mark_end
          def method6
          end
        end

        class Test2
          # @return String
          def self.method5
            "Im method 5"
          end

          # @return Array
          def method6
            [1,
             2,
             3,
             0]
          end
        end
      }

      it "complies comments references" do
        result = described_class.new(Test, [:method2, :method3, :method4, :method5, :method6]).to_hash

        expect(convert_method_hash result).to eq({ :method2 => "{:key=>\"fun\"}\n", method3: "Im method 5\n", :method4 => "[1,\n2,\n3,\n0]\nWhatever!\n", :method5 => "[1, 2, 3, 0]\n", :method6 => "im 5\n" })
      end
    end

    context "scoping" do
      let!(:ruby_class) {
        class Test
          CONSTANT = 109

          #=mark_doc
          # <%= CONSTANT %>
          # <%= Test::CONSTANT %>
          # <%= method3 %>
          #=mark_end
          def method2
          end

          def self.method3
            "hello"
          end
        end
      }

      it "complies comments references" do
        result = described_class.new(Test, [:method2]).to_hash

        expect(convert_method_hash result).to eq({ method2: "109\n109\nhello\n" })
      end
    end

    context "link to method source in GitHub" do
      let!(:ruby_class) {
        class Test

          #=mark_doc
          # <%= git_hub_method_url(".def_on_github") %>
          # <%= git_hub_file_url("spec/markdown_ruby_documentation/template_parser_spec.rb") %>
          #=mark_end
          def method2
          end

          def self.def_on_github
            "hello"
          end
        end
      }

      it do
        result = described_class.new(Test, [:method2]).to_hash

        expect(convert_method_hash result).to eq({ method2: "https://github.com/zeisler/markdown_ruby_documentation/blob/master/spec/markdown_ruby_documentation/template_parser_spec.rb#L146\nhttps://github.com/zeisler/markdown_ruby_documentation/blob/master/spec/markdown_ruby_documentation/template_parser_spec.rb\n" })
      end
    end

    context "when only including mark_doc and no mark_end" do
      let!(:ruby_class) {
        class Test

          #=mark_doc
          #hello
          def document_me
          end
        end
      }

      it "adds comment at the end and parse the whole comment" do
        result = described_class.new(Test, [:document_me]).to_hash

        expect(convert_method_hash result).to eq({ document_me: "hello\n[//]: # (This method has no mark_end)" })
      end
    end

    context "pretty_code" do
      let!(:ruby_class) {
        class Test

          #=mark_doc
          # <%= pretty_code(print_method_source("#format_me")) %>
          def format_me
            return unless true
            return if true
            @memoization ||= if :this_thing_works? && true || false
                               :run_the_system_30_day && 1_000
                               'under_review'
                             end
            true ? 'eligible' : 'decline'
          end
        end
      }

      it "adds comment at the end and parse the whole comment" do
        result = described_class.new(Test, [:format_me]).to_hash

        expect(convert_method_hash result).to eq({ format_me: <<~TEXT.chomp })
          return nothing unless true
          return nothing if true
          if 'This thing works?' and true or false
          'Run the system 30 day' and 1,000
          'under review'
          end
          if true
          'eligible'
          else
          'decline'
          end
          [//]: # (This method has no mark_end)
        TEXT
      end
    end

    context "git_hub_file_url" do
      let!(:ruby_class) {
        class Test

          #=mark_doc
          # <%= git_hub_file_url("MarkdownRubyDocumentation::TemplateParser") %>
          #=mark_end
          # @return [NilClass]
          def method10
          end
        end
      }

      it "gets the git hub url for that constant" do
        result = described_class.new(Test, [:method10]).to_hash

        expect(convert_method_hash result).to eq({ method10: "https://github.com/zeisler/markdown_ruby_documentation/blob/master/lib/markdown_ruby_documentation/template_parser.rb#L10\n" })
      end
    end

    context "format_link" do
      let!(:ruby_class) {
        class Test

          #=mark_doc
          # <%= format_link *title_from_link("#i_do_other_things") %>
          # <%= format_link "The method 10", "#i_do_other_things?" %>
          # <%= format_link "GoodBye", "path/to_the_thing#hello-goodbye" %>
          # <%= format_link *title_from_link("path/to_the_thing#hello-goodbye") %>
          # <%= format_link *title_from_link("path/to_the_other_thing") %>
          #=mark_end
          def i_do_something
          end
        end
      }

      it "auto formatting and custom" do
        result = described_class.new(Test, [:i_do_something]).to_hash

        expect(convert_method_hash result).to eq({ i_do_something: "[I do other things](#i-do-other-things)\n[The method 10](#i-do-other-things)\n[GoodBye](path/to_the_thing#hello-goodbye)\n[Hello-goodbye](path/to_the_thing#hello-goodbye)\n[To the other thing](path/to_the_other_thing)\n" })
      end
    end

    context "__method__" do
      let!(:ruby_class) {
        class Test

          #=mark_doc
          # <%= __method__ %>
          #=mark_end
          def i_do_other_things
          end

          #=mark_doc
          # <%= print_mark_doc_from "#i_do_other_things" %>
          #=mark_end
          def i_do_limited_things
          end
        end
      }

      it "returns the commented method name" do
        result = described_class.new(Test, [:i_do_other_things, :i_do_limited_things]).to_hash

        expect(convert_method_hash result).to eq({ :i_do_other_things => "#i_do_other_things\n", :i_do_limited_things => "#i_do_other_things\n\n" })
      end
    end

    context "variables_as_local_links" do
      let!(:ruby_class) {
        class Test

          #=mark_doc
          # <%= variables_as_local_links print_method_source(__method__) %>
          # <%= variables_as_local_links "* __When__" %>
          #=mark_end
          def i_add_stuff
            i_return_one + i_return_two + "hello"
          end

          def i_return_one
            1
          end

          def i_return_two
            2
          end
        end
      }

      it "returns the commented method name" do
        result = described_class.new(Test, [:i_add_stuff]).to_hash

        expect(convert_method_hash result).to eq({ :i_add_stuff => "^`i_return_one` + ^`i_return_two` + \"hello\"\n* __When__\n" })
      end
    end

    context "quoted_strings_as_local_links" do
      let!(:ruby_class) {
        class Test

          #=mark_doc
          # <%= quoted_strings_as_local_links print_method_source(__method__) %>
          #=mark_end
          def i_add_stuff
            'I return one Hello' + 'Site x property value'
          end
        end
      }

      it "returns the commented method name" do
        result = described_class.new(Test, [:i_add_stuff]).to_hash

        expect(convert_method_hash result).to eq({ :i_add_stuff => "^`i_return_one_hello` + ^`site_x_property_value`\n" })
      end
    end

    context "constants_with_name_and_value" do
      let!(:ruby_class) {
        class Test
          MAX_COMBINED_LIEN_TO_VALUE_RATIO_SAN_DIEGO = 3
          MAX_COMBINED_LIEN_TO_VALUE_RATIO_UCCC      = 2
          #=mark_doc
          # <%= constants_with_name_and_value print_method_source(__method__) %>
          #=mark_end
          def i_add_stuff
            if true
              MAX_COMBINED_LIEN_TO_VALUE_RATIO_SAN_DIEGO
            else
              MAX_COMBINED_LIEN_TO_VALUE_RATIO_UCCC
            end
          end
        end
      }

      it "returns the commented method name" do
        result = described_class.new(Test, [:i_add_stuff]).to_hash

        expect(convert_method_hash result).to eq({ :i_add_stuff => "if true\n`MAX_COMBINED_LIEN_TO_VALUE_RATIO_SAN_DIEGO => 3`\nelse\n`MAX_COMBINED_LIEN_TO_VALUE_RATIO_UCCC => 2`\nend\n" })
      end
    end

    context "ruby_to_markdown" do
      let!(:ruby_class) {
        class Test
          #=mark_doc
          # <%= ruby_to_markdown print_method_source(__method__) %>
          #=mark_end
          def i_add_stuff
            if true
              1
            else
              2
            end

            case
            when true
              'unavailable'
            else
              'eligible'
            end

            case true
            when true
              'unavailable'
            end
          end
        end
      }

      it "returns the commented method name" do
        result = described_class.new(Test, [:i_add_stuff]).to_hash

        expect(convert_method_hash result).to eq({ :i_add_stuff => <<~TEXT })
          * __If__ true
          __Then__
          1
          * __Else__
          __Then__
          2
          end

          * __Given__
          * __When__ true
          __Then__
          'unavailable'
          * __Else__
          __Then__
          'eligible'
          end

          * __Given__ true
          * __When__ true
          __Then__
          'unavailable'
          end
        TEXT
      end
    end
  end
end
