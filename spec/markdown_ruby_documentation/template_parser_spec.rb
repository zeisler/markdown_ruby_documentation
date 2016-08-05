RSpec.describe MarkdownRubyDocumentation::TemplateParser do

  let(:output_object){ double("output_object", relative_dir: "spec") }
  let(:load_path){__FILE__}

  before do
    MarkdownRubyDocumentation::Generate.load_path = load_path
    MarkdownRubyDocumentation::Generate.output_object = output_object
  end

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

    context "when including a module methods" do
      let!(:ruby_class) {
        class Test
          module TestModule
            #=mark_doc
            # You should see this!
            #=mark_end
            def test1

            end
          end

          include TestModule
        end
      }

      it do
        result = described_class.new(Test, [:test1]).to_hash
        expect(convert_method_hash(result)).to eq( {:test1=>"You should see this!\n"})
      end
    end

    context "eval_method:" do
      let!(:ruby_class) {
        module Nesting
          class Test
            SCOPED_CONSTANT_VALUE = "1001"

            def self.method1
              { key: "fun" }
            end

            #=mark_doc
            # <%= eval_method ".method1" %>
            #=mark_end
            def method2
            end

            #=mark_doc
            # <%= eval_method("Test2.method7") %>
            #=mark_end
            def method3
            end

            #=mark_doc
            # <%= print_method_source("Test2#method8") %>
            # Whatever!
            #=mark_end
            def method4
              "im 4"
            end

            #=mark_doc
            # <%= eval_method("Test2#method8") %>
            #=mark_end
            def method5
              "im 5" + method4 + SCOPED_CONSTANT_VALUE
            end

            #=mark_doc
            # <%= eval_method("#method6") %>
            #=mark_end
            def method6
              method5
            end
          end
        end

        class Test2
          # @return String
          def self.method7
            "Im method 7"
          end

          # @return Array
          def method8
            [1,
             2,
             3,
             0]
          end
        end
      }

      it "complies comments references" do
        result = described_class.new(Nesting::Test, [
          :method2,
          :method3,
          :method4,
          :method5,
          :method6,
        ]).to_hash

        expect(convert_method_hash result).to eq({ :method2 => "{:key=>\"fun\"}\n", method3: "Im method 7\n", :method4 => "[1,\n2,\n3,\n0]\nWhatever!\n", :method5 => "[1, 2, 3, 0]\n", :method6 => "im 5im 41001\n" })
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

        expect(convert_method_hash result).to eq({ method2: "https://github.com/zeisler/markdown_ruby_documentation/blob/master/spec/markdown_ruby_documentation/template_parser_spec.rb#L189\nhttps://github.com/zeisler/markdown_ruby_documentation/blob/master/spec/markdown_ruby_documentation/template_parser_spec.rb\n" })
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

        expect(convert_method_hash result).to eq({ document_me: "hello\n" })
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

    context "methods_as_local_links" do
      let!(:ruby_class) {
        class Test

          #=mark_doc
          # <%= methods_as_local_links print_method_source(__method__), { call_on_title: false } %>
          # <%= methods_as_local_links "* __When__" %>
          #=mark_end
          def i_add_stuff
            i_return_one + i_return_two? + "hello"
          end

          def i_return_one
            1
          end

          def i_return_two?
            2
          end
        end
      }

      it "returns the commented method name" do
        result = described_class.new(Test, [:i_add_stuff]).to_hash

        expect(convert_method_hash result).to eq({ :i_add_stuff => "[i_return_one](https://github.com/zeisler/markdown_ruby_documentation/blob/master/spec/test.md#i-return-one) + [i_return_two?](https://github.com/zeisler/markdown_ruby_documentation/blob/master/spec/test.md#i-return-two) + \"hello\"\n* __When__\n" })
      end
    end

    context "convert_early_return_to_if_else" do
      let!(:ruby_class) {
        class Test

          #=mark_doc
          # <%= convert_early_return_to_if_else print_method_source __method__ %>
          #=mark_end
          def i_add_stuff
            return true if false
            if :true
              :do_stuff
            end
          end
        end
      }

      it "returns the commented method name" do
        result = described_class.new(Test, [:i_add_stuff]).to_hash

        expect(convert_method_hash result).to eq({ :i_add_stuff => <<~TEXT })
          if false
          return true
          end
          if :true
          :do_stuff
          end
        TEXT
      end
    end

    context "readable_ruby_numbers" do
      let!(:ruby_class) {
        class Test

          #=mark_doc
          # <%= readable_ruby_numbers print_method_source __method__ %>
          #=mark_end
          def i_add_stuff
            1 + 1_000 + 90_1_1_1 + 10 + 90000.9
          end
        end
      }

      it "returns the commented method name" do
        result = described_class.new(Test, [:i_add_stuff]).to_hash

        expect(convert_method_hash result).to eq({ :i_add_stuff => <<~TEXT })
          1 + 1,000 + 90,111 + 10 + 90,000.9
        TEXT
      end
    end

    context "constants_with_name_and_value" do
      let!(:ruby_class) {
        class Test
          MAX_COMBINED_LIEN_TO_VALUE_RATIO_SAN_DIEGO = 3
          MAX_COMBINED_LIEN_TO_VALUE_RATIO_UCCC      = 2
          #=mark_doc
          # <%= constants_with_name_and_value print_method_source %>
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

        expect(convert_method_hash result).to eq({ :i_add_stuff => <<~MARKDOWN})
          if true
          [3](#max-combined-lien-to-value-ratio-san-diego)
          else
          [2](#max-combined-lien-to-value-ratio-uccc)
          end
        MARKDOWN
      end

      context "with proc" do
        let!(:ruby_class) {
          class Test
            MAX_COMBINED_LIEN_TO_VALUE_RATIO_SAN_DIEGO = 3
            MAX_COMBINED_LIEN_TO_VALUE_RATIO_UCCC      = 2
            #=mark_doc
            # <%= constants_with_name_and_value print_method_source, proc: -> (r,m,o){ "[#{m}](#{o[:link]})" } %>
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

          expect(convert_method_hash result).to eq({ :i_add_stuff => <<~MARKDOWN})
          if true
          [MAX_COMBINED_LIEN_TO_VALUE_RATIO_SAN_DIEGO](#max-combined-lien-to-value-ratio-san-diego)
          else
          [MAX_COMBINED_LIEN_TO_VALUE_RATIO_UCCC](#max-combined-lien-to-value-ratio-uccc)
          end
          MARKDOWN
        end
      end


    end

    describe "ruby_to_markdown" do

      context "with print_method_source" do
        let!(:ruby_class) {
          class Test
            #=mark_doc
            # <%= ruby_to_markdown print_method_source(__method__) %>
            #=mark_end
            def i_add_stuff
              return if true
              return unless false
              if true
                1
              else
                2 + :end
              end

              case
              when true
                'unavailable' + this_thing_works?
              else
                'eligible' + public_1method
              end

              case true
              when true
                'unavailable'
              end
            end

            def public_1method

            end

            private

            def this_thing_works?

            end
          end
        }

        it "returns the commented method name" do
          result = described_class.new(Test, [:i_add_stuff]).to_hash

          expect(convert_method_hash result).to eq({ :i_add_stuff => <<~TEXT })
            * __If__ true
            __Then__
            return nothing
            * __Unless__ false
            __Then__
            return nothing
            * __If__ true
            __Then__
            1
            * __Else__
            2 + :end

            * __Given__
            * __When__ true
            __Then__
            'unavailable' + [This Thing Works?](https://github.com/zeisler/markdown_ruby_documentation/blob/master/spec/test.md#this-thing-works)
            * __Else__
            'eligible' + [Public 1method](https://github.com/zeisler/markdown_ruby_documentation/blob/master/spec/test.md#public-1method)

            * __Given__ true
            * __When__ true
            __Then__
            'unavailable'

          TEXT
        end
      end

      context "with a method_reference and no reference" do
        let!(:ruby_class) {
          class Test
            #=mark_doc
            # <%= ruby_to_markdown %>
            # <%= ruby_to_markdown(method_reference: "#rule_name", methods_as_local_links: { call_on_title: :humanize }) %>
            #=mark_end
            def decision_from_rule
              case
              when data_unavailable?
                'unavailable'
              when declared_bankruptcy_recently?(with_in_years: bankruptcy_allowed_years_ago)
                'decline'
              when address.los_angeles_county?
                'decline'
              else
                'eligible'
              end
            end

            def data_unavailable?

            end

            def declared_bankruptcy_recently?(*args)

            end

            def bankruptcy_allowed_years_ago

            end

            #=mark_doc
            # <%= ruby_to_markdown %>
            def rule_name
              case
              when address.nil?
                'bankruptcy_declared'
              end
            end

            def address
            end
          end
        }

        it "returns the commented method name" do
          result = described_class.new(Test, [:decision_from_rule]).to_hash

          expect(convert_method_hash result).to eq({ :decision_from_rule => <<~TEXT })
            * __Given__
            * __When__ [Data Unavailable?](https://github.com/zeisler/markdown_ruby_documentation/blob/master/spec/test.md#data-unavailable)
            __Then__
            'unavailable'
            * __When__ [Declared Bankruptcy Recently?](https://github.com/zeisler/markdown_ruby_documentation/blob/master/spec/test.md#declared-bankruptcy-recently)(with_in_years: [Bankruptcy Allowed Years Ago](https://github.com/zeisler/markdown_ruby_documentation/blob/master/spec/test.md#bankruptcy-allowed-years-ago))
            __Then__
            'decline'
            * __When__ [Address](https://github.com/zeisler/markdown_ruby_documentation/blob/master/spec/test.md#address) is los_angeles_county?
            __Then__
            'decline'
            * __Else__
            'eligible'

            * __Given__
            * __When__ [Address](https://github.com/zeisler/markdown_ruby_documentation/blob/master/spec/test.md#address) is missing?
            __Then__
            'bankruptcy_declared'

          TEXT
        end
      end

      context "ruby_to_markdown with no source" do
        let!(:ruby_class) {
          class Test
            #=mark_doc
            # <%= ruby_to_markdown(methods_as_local_links: { call_on_title: false })  %>
            #=mark_end
            def i_add_stuff
              return if true
              if true
                1
              else
                2 + :end
              end

              case
              when true
                'unavailable' && this_thing_works?
              else
                'eligible' + public_1method
              end

              case true
              when true
                'unavailable'
              end
            end

            def public_1method

            end

            private

            def this_thing_works?

            end
          end
        }

        it "returns the commented method name" do
          result = described_class.new(Test, [:i_add_stuff]).to_hash

          expect(convert_method_hash result).to eq({ :i_add_stuff => <<~TEXT })
            * __If__ true
            __Then__
            return nothing
            * __If__ true
            __Then__
            1
            * __Else__
            2 + :end

            * __Given__
            * __When__ true
            __Then__
            'unavailable' and [this_thing_works?](https://github.com/zeisler/markdown_ruby_documentation/blob/master/spec/test.md#this-thing-works)
            * __Else__
            'eligible' + [public_1method](https://github.com/zeisler/markdown_ruby_documentation/blob/master/spec/test.md#public-1method)

            * __Given__ true
            * __When__ true
            __Then__
            'unavailable'

          TEXT
        end
      end

      context "ruby_to_markdown edge case with comment" do
        let!(:ruby_class) {
          class Test
            LIEN_TO_VALUE_THRESHOLD = 80

            #=mark_doc
            # <%= ruby_to_markdown %>
            def the_method_name(value:)
              if identifier == "first"
                # NOTE: rule is "15% of value value up to 700_000, 10% of any additional value"
                value * 0.15 - [0, value - 700_000].max * 0.05
              elsif identifier == "last"
                1 <= LIEN_TO_VALUE_THRESHOLD
              end
            end
          end
        }

        it "returns the commented method name" do
          result = described_class.new(Test, [:the_method_name]).to_hash

          expect(convert_method_hash result).to eq({ :the_method_name => <<~TEXT })
            * __If__ identifier Equal to "first"
            __Then__
            </br>*( NOTE: rule is "15% of value value up to 700,000, 10% of any additional value")*</br>
            value * 0.15 - [0, value - 700,000].max * 0.05
            * __Else If__ identifier Equal to "last"
            __Then__
            1 is less than or equal to [80](#lien-to-value-threshold)

          TEXT
        end
      end
    end

    describe "hash_to_markdown_table" do
      let!(:ruby_class) { class Test; end }
      subject { described_class.new(Test, [:method]) }

      it "returns a table" do
        hash = { :one => "one", :two => "two" }
        expect(subject.hash_to_markdown_table(hash, key_name: "something", value_name: "hey")).to eq(<<~TABLE[0..-2]
          | something  | hey |
          |------------|-----|
          | one        | one |
          | two        | two |
        TABLE
        )
      end

      context "hash with null values" do
        it "returns a table with empty value for null" do
          hash = { :one => "one", :two => nil }
          expect(subject.hash_to_markdown_table(hash, key_name: "something", value_name: "hey")).to eq(<<~TABLE[0..-2]
            | something  | hey |
            |------------|-----|
            | one        | one |
            | two        |     |
          TABLE
          )
        end
      end
    end
  end
end
