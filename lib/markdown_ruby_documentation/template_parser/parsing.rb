module MarkdownRubyDocumentation
  class TemplateParser
    module Parsing
      def parse_erb(str, method)
        filename, lineno = ruby_class_meth_source_location(method)
        adjusted_lineno  = (lineno - ruby_class_meth_comment(method).split("\n").count-1)
        ruby_class.module_eval(<<-RUBY, __FILE__, __LINE__+1)
        def self.get_binding
          self.send(:binding)
        end
        RUBY
        ruby_class.send(:define_singleton_method, :current_method) do
          method
        end

        ruby_class.send(:define_singleton_method, :output_object) do
          output_object
        end

        ruby_class.send(:define_singleton_method, :load_path) do
          load_path
        end

        ruby_class.extend(CommentMacros)

        erb          = ERB.new(str, nil, "-")

        erb.lineno   = adjusted_lineno if erb.respond_to?(:lineno)
        erb.filename = filename if erb.respond_to?(:filename)
        erb.result(ruby_class.get_binding)
      rescue => e
        raise e.class, e.message, ["#{filename}:#{adjusted_lineno}:in `#{method.name}'", *e.backtrace]
      end

      def insert_method_name(string, method)
        string.gsub("__method__", "'#{method.to_s}'")
      end

      def strip_comment_hash(str)
        str.gsub(/^#[\s]?/, "")
      end

      def ruby_class_meth_comment(method)
        method.context.public_send(method.type, method.name).comment

      rescue MethodSource::SourceNotFoundError => e
        raise e.class, "#{ method.context}#{method.type_symbol}#{method.name}, \n#{e.message}"
      end

      def ruby_class_meth_source_location(method)
        method.context.public_send(method.type, method.name).source_location
      end

      def extract_dsl_comment(comment_string)
        if (v = when_start_and_end(comment_string))
          v
        elsif (x = when_only_start(comment_string))
          x
        else
          ""
        end
      end

      def when_start_and_end(comment_string)
        v = /#{START_TOKEN}\n((.|\n)*)#{END_TOKEN}/.match(comment_string)
        v.try!(:captures).try!(:first)
      end

      def when_only_start(comment_string)
        v = /#{START_TOKEN}\n((.|\n)*)/.match(comment_string)
        v.try!(:captures).try!(:first)
      end

      def extract_dsl_comment_from_method(method)
        extract_dsl_comment strip_comment_hash(ruby_class_meth_comment(method))
      end
    end
  end
end
