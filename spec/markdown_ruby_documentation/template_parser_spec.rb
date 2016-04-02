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

        expect(result).to eq({ method1: "", method2: "This method does stuff\nHello\n\n", :method4 => "Goodbye\n\nHello\n" })
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

        expect(result).to eq({ :method2 => "{:key=>\"fun\"}\n", method3: "Im method 5\n", :method4 => "[1,\n2,\n3,\n0]\nWhatever!\n", :method5 => "[1, 2, 3, 0]\n", :method6 => "im 5\n" })
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

        expect(result).to eq({ method2: "109\n109\nhello\n" })
      end
    end
  end
end
