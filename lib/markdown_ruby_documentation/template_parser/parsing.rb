module MarkdownRubyDocumentation
  class TemplateParser
    module Parsing
      def parse_erb(str, method)
        filename, lineno = ruby_class_meth_source_location(method)
        adjusted_lineno  = (lineno - ruby_class_meth_comment(method).split("\n").count-1)
        method.context.module_eval(<<-RUBY, __FILE__, __LINE__+1)
        def self.get_binding
          self.send(:binding)
        end
        RUBY
        method.context.send(:define_singleton_method, :current_method) do
          method
        end

        method.context.send(:define_singleton_method, :output_object) do
          output_object
        end

        method.context.send(:define_singleton_method, :load_path) do
          load_path
        end

        method.context.extend(CommentMacros)

        erb          = ERB.new(str, nil, "-")

        erb.lineno   = adjusted_lineno if erb.respond_to?(:lineno)
        erb.filename = filename if erb.respond_to?(:filename)
        erb.result(method.context.get_binding)
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
        comment = method.context.public_send(method.type, method.name).comment
        if comment.blank?
          look_for_class_macro_comment(method)
        else
          comment
        end
      rescue MethodSource::SourceNotFoundError => e
        raise e.class, "#{ method.context}#{method.type_symbol}#{method.name}, \n#{e.message}"
      end

      CLASS_MACROS = [
        ->(name) {"attribute #{Regexp.escape(name.inspect)}"},
        ->(name) {"def_delegator :.*, #{Regexp.escape(name.inspect)}"},
      ]
      def source_location(file_path, name)
        return unless file_path && name
        found_match = nil
        CLASS_MACROS.each do |macro|
          if (ln = get_line_number(file_path.split(":").first, macro.call(name)))
            found_match = ln
          end
        end
        [file_path, found_match] if found_match
      end

      def get_line_number(file, word)
        return unless file && word
        `grep -nrH -m 1 "^[\s]*#{word}" #{file}`.match(/#{file}:(\d*)/).to_a[1].try!(:to_i)
      end

      def look_for_class_macro_comment(method)
        return "" unless (sl = source_location(method.file_path, method.name))
        MethodSource.comment_helper(sl, method.name).tap do |comment|
          method.line_no = sl[1] unless comment.blank?
        end
      end

      def ruby_class_meth_source_location(method)
        method.context.public_send(method.type, method.name).source_location
      end

      def extract_dsl_comment(comment_string)
        [when_start_and_end(comment_string), when_only_start(comment_string), ""].compact.first
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
