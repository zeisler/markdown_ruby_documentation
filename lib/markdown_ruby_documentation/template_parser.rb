module MarkdownRubyDocumentation
  class TemplateParser

    def initialize(ruby_class, methods)
      @ruby_class        = ruby_class
      @methods           = methods.map { |method| method.is_a?(Symbol) ? InstanceMethod.new("##{method}", context: ruby_class) : method }
      @erb_methods_class = erb_methods_class
    end

    def to_hash(*args)
      parser
    end

    alias_method :call, :to_hash

    private

    IGNORE_METHODS = %w(
      initialize
      inherited
      included
      extended
      prepended
      method_added
      method_undefined
      alias_method
      append_features
      attr
      attr_accessor
      attr_reader
      attr_writer
      define_method
      extend_object
      method_removed
      module_function
      prepend_features
      private
      protected
      public
      refine
      remove_const
      remove_method
      undef_method
      using
    )

    attr_reader :ruby_class, :methods, :erb_methods_class

    def parser
      @parser ||= methods.each_with_object({}) do |method, hash|
        begin
          value = parse_erb(insert_method_name(strip_comment_hash(extract_dsl_comment_from_method(method)), method), method)
        rescue MethodSource::SourceNotFoundError => e
          value = false
          puts e.message unless IGNORE_METHODS.any? { |im| e.message.include? im }
        end
        if value
          hash[method.name] = { text: value, method_object: method }
        end
      end
    end

    module CommentMacros

      # @param [String] str
      # @example
      # @return [String] of any comments proceeding a method def
      def print_raw_comment(str)
        strip_comment_hash(ruby_class_meth_comment(Method.create(str, context: ruby_class)))
      end

      # @param [String] str
      # @example
      # @return [String]
      def print_mark_doc_from(str)
        method = Method.create(str, context: ruby_class)
        parse_erb(insert_method_name(extract_dsl_comment(print_raw_comment(str)), method), method)
      end

      # @param [String] str
      # @example
      # @return [Object] anything that the evaluated method would return.
      def eval_method(str)
        case (method = Method.create(str, context: ruby_class))
        when ClassMethod
          k = get_context_class(method)
          k.public_send(method.name)
        when InstanceMethod
          InstanceToClassMethods.new(method: method).eval_instance_method
        end
      end

      # @param [String] input
      # @return [String] the source of a method block is returned as text.
      def print_method_source(input)
        method = Method.create(input.dup, context: ruby_class)
        PrintMethodSource.new(method: method).print
      end

      def git_hub_method_url(input)
        method = Method.create(input.dup, context: ruby_class)
        GitHubLink::MethodUrl.new(subject: get_context_class(method), method_object: method)
      end

      def git_hub_file_url(file_path)
        if file_path.include?("/")
          GitHubLink::FileUrl.new(file_path: file_path)
        else
          const    = Object.const_get(file_path)
          a_method = const.public_instance_methods.first
          git_hub_method_url("#{file_path}##{a_method}")
        end
      end

      def pretty_code(source_code, humanize: true)
        source_code = ternary_to_if_else(source_code)
        source_code = pretty_early_return(source_code)
        source_code.gsub!(/@[a-z][a-z0-9_]+ \|\|=?\s/, "") # @memoized_vars ||=
        source_code.gsub!(":", '')
        source_code.gsub!("&&", "and")
        source_code.gsub!(">=", "is greater than or equal to")
        source_code.gsub!("<=", "is less than or equal to")
        source_code.gsub!(" < ", " is less than ")
        source_code.gsub!(" > ", " is greater than ")
        source_code.gsub!(" == ", " Equal to ")
        source_code.gsub!("nil?", "is missing?")
        source_code.gsub!("elsif", "else if")
        source_code.gsub!("||", "or")
        source_code.gsub!(/([0-9][0-9_]+[0-9]+)/) do |match|
          match.gsub("_", ",")
        end
        if humanize
          source_code.gsub!(/["']?[a-z_A-Z?!0-9]*["']?/) do |s|
            if s.include?("_") && !(/["'][a-z_A-Z?!0-9]*["']/ =~ s)
              "'#{s.humanize}'"
            else
              s.humanize(capitalize: false)
            end
          end
        end
        source_code
      end

      def readable_ruby_numbers(source_code, &block)
        source_code.gsub(/([0-9][0-9_]+[0-9]+)/) do |match|
          value = eval(match)
          if block_given?
            block.call(value)
          else
            ActiveSupport::NumberHelper.number_to_delimited(value)
          end
        end
      end

      def link_local_methods_from_pretty_code(pretty_code, include: nil)
        pretty_code.gsub(/([`][a-zA-Z_0-9!?\s]+[`])/) do |match|
          include_code(include, match) do
            variables_as_local_links match.underscore.gsub(" ", "_").gsub(/`/, "")
          end
        end
      end

      def include_code(include, text, &do_action)
        if include.nil? || (include.present? && include.include?(remove_quotes(text)))
          do_action.call(text)
        else
          text
        end
      end

      private :include_code

      def convert_early_return_to_if_else(source_code)
        source_code.gsub(/(.+) if (.+)/, "if \\2\n\\1\nend")
      end

      def pretty_early_return(source_code)
        source_code.gsub(/return (unless|if)/, 'return nothing \1')
      end

      def ternary_to_if_else(ternary)
        ternary.gsub(/(.*) \? (.*) \: (.*)/, "if \\1\n\\2\nelse\n\\3\nend")
      end

      def format_link(title, link_ref)
        path, anchor   = *link_ref.to_s.split("#")
        formatted_path = [path, anchor.try!(:dasherize).try!(:delete, "?")].compact.join("#")
        "[#{title}](#{formatted_path})"
      end

      def title_from_link(link_ref)
        [link_ref.split("/").last.split("#").last.to_s.humanize, link_ref]
      end

      def link_to_markdown(klass, title:)
        return super if defined? super
        raise "Client needs to define MarkdownRubyDocumentation::TemplateParser::CommentMacros#link_to_markdown"
      end

      def method_as_local_links(ruby_source)
        ruby_source.gsub(/(\b(?<!['"])[a-z_][a-z_0-9?!]*(?!['"]))/) do |match|
          is_a_method_on_ruby_class?(match) ? "^`#{match}`" : match
        end
      end

      alias_method(:variables_as_local_links, :method_as_local_links)

      def quoted_strings_as_local_links(text, include: nil)
        text.gsub(/(['|"][a-zA-Z_0-9!?\s]+['|"])/) do |match|
          include_code(include, match) do
            "^`#{remove_quotes(match).underscore.gsub(" ", "_")}`"
          end
        end
      end

      def constants_with_name_and_value(ruby_source)
        ruby_source.gsub(/([A-Z]+[A-Z_0-9]+)/) do |match|
          value = ruby_class.const_get(match)
          "`#{match} => #{value.inspect}`"
        end
      end

      def ruby_to_markdown(ruby_source)
        ruby_source = readable_ruby_numbers(ruby_source)
        ruby_source = pretty_early_return(ruby_source)
        ruby_source = convert_early_return_to_if_else(ruby_source)
        ruby_source = ternary_to_if_else(ruby_source)
        ruby_source = ruby_if_statement_to_md(ruby_source)
        ruby_source = ruby_case_statement_to_md(ruby_source)
        ruby_source = remove_end_keyword(ruby_source)
      end

      def remove_end_keyword(ruby_source)
        ruby_source.gsub!(/^[\s]*end\n?/, "")
      end

      def ruby_if_statement_to_md(ruby_source)
        ruby_source.gsub!(/else if(.*)/, "* __ElseIf__\\1\n__Then__")
        ruby_source.gsub!(/elsif(.*)/, "* __ElseIf__\\1\n__Then__")
        ruby_source.gsub!(/if(.*)/, "* __If__\\1\n__Then__")
        ruby_source.gsub!("else", "* __Else__")
        ruby_source
      end

      def ruby_case_statement_to_md(ruby_source)
        ruby_source.gsub!(/case(.*)/, "* __Given__\\1")
        ruby_source.gsub!(/when(.*)/, "* __When__\\1\n__Then__")
        ruby_source.gsub!("else", "* __Else__")
        ruby_source
      end

      def hash_to_markdown_table(hash, key_name:, value_name:)
        key_max_length   = [hash.keys.group_by(&:size).max.first, key_name.size + 1].max
        value_max_length = [hash.values.group_by(&:size).max.first, value_name.size + 1].max
        header           = markdown_table_header([[key_name, key_max_length+2], [value_name, value_max_length+2]])
        rows             = hash.map { |key, value| "| #{key.to_s.ljust(key_max_length)} | #{value.to_s.ljust(value_max_length)}|" }.join("\n")
        [header, rows].join("\n")
      end

      def array_to_markdown_table(array, key_name:)
        key_max_length = [array.group_by(&:size).max.first, key_name.size + 1].max
        header         = markdown_table_header([[key_name, key_max_length+3]])
        rows           = array.map { |key| "| #{key.to_s.ljust(key_max_length)} |" }.join("\n")
        [header, rows].join("\n")
      end

      def markdown_table_header(array_headers)
        parts      = array_headers.map do |header, pad_length=0|
          " #{header.ljust(pad_length-1)}"
        end
        bar        = parts.map(&:length).map do |length|
          ("-" * (length))
        end.join("|")
        bar[-1]    = "|"
        header     = parts.join("|")
        header[-1] = "|"
        [("|" + header), ("|" + bar)].join("\n")
      end

      private

      def is_a_method_on_ruby_class?(method)
        [*ruby_class.public_instance_methods, *ruby_class.private_instance_methods].include?(remove_quotes(method).to_sym)
      end

      def remove_quotes(string)
        string.gsub(/['|"]/, "")
      end

      def insert_method_name(string, method)
        string.gsub("__method__", "'#{method.to_s}'")
      end

      def parse_erb(str, method)
        filename, lineno = ruby_class_meth_source_location(method)

        ruby_class.module_eval(<<-RUBY, __FILE__, __LINE__+1)
        def self.get_binding
          self.send(:binding)
        end
        RUBY
        ruby_class.extend(CommentMacros)
        erb = ERB.new(str, nil, "-")
        erb.result(ruby_class.get_binding)
      rescue => e
        raise e.class, e.message, ["#{filename}:#{lineno}:in `#{method.name}'", *e.backtrace]
      end

      def strip_comment_hash(str)
        str.gsub(/^#[\s]?/, "")
      end

      def ruby_class_meth_comment(method)
        get_context_class(method).public_send(method.type, method.name).comment

      rescue MethodSource::SourceNotFoundError => e
        raise e.class, "#{get_context_class(method)}#{method.type_symbol}#{method.name}, \n#{e.message}"
      end

      def ruby_class_meth_source_location(method)
        get_context_class(method).public_send(method.type, method.name).source_location
      end

      def extract_dsl_comment(comment_string)
        if (v = when_start_and_end(comment_string))
          v
        elsif (x = when_only_start(comment_string))
          x << "[//]: # (This method has no mark_end)"
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

      def ruby_class
        @ruby_class || self
      end

      def get_context_class(method)
        method.context
      end
    end
    include CommentMacros
  end
end
