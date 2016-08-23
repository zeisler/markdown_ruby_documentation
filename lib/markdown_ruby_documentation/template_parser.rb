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

    attr_reader :ruby_class, :methods, :erb_methods_class, :current_method, :output_object, :load_path

    def parser
      @parser ||= methods.each_with_object({}) do |method, hash|
        begin
          @current_method = method
          value           = parse_erb(insert_method_name(strip_comment_hash(extract_dsl_comment_from_method(method)), method), method)
        rescue MethodSource::SourceNotFoundError => e
          @current_method = nil
          value           = false
        end
        if value
          hash[method.name] = { text: value, method_object: method }
        end
      end
    end

    module CommentMacros
      include Parsing
      attr_accessor :output_object
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
      def eval_method(str=current_method)
        case (method = Method.create(str, context: ruby_class))
        when ClassMethod
          method.context.public_send(method.name)
        when InstanceMethod
          InstanceToClassMethods.new(method: method).eval_instance_method
        end
      end

      # @param [String] method_reference
      # @return [String] the source of a method block is returned as text.
      def print_method_source(method_reference=current_method)
        method = Method.create(method_reference.dup, context: ruby_class)
        PrintMethodSource.new(method: method).print
      end


      # @param [String] method_reference
      def git_hub_method_url(method_reference=current_method)
        method = Method.create(method_reference.dup, context: ruby_class)
        GitHubLink::MethodUrl.new(subject: method.context, method_object: method)
      end

      def git_hub_file_url(file_path_or_const)
        if file_path_or_const.include?("/")
          GitHubLink::FileUrl.new(file_path: file_path_or_const)
        else
          const    = Object.const_get(file_path_or_const)
          a_method = const.public_instance_methods.first
          git_hub_method_url("#{file_path_or_const}##{a_method}")
        end
      end

      RUBY_TO_MARKDOWN_PROCESSORS = [
        :readable_ruby_numbers,
        :pretty_early_return,
        :convert_early_return_to_if_else,
        :ternary_to_if_else,
        :ruby_if_statement_to_md,
        :ruby_case_statement_to_md,
        :ruby_operators_to_english,
        :nil_check_readable,
        :question_mark_method_format,
        :methods_as_local_links,
        :remove_end_keyword,
        :constants_with_name_and_value,
        :remove_memoized_vars,
        :comment_format
      ]

      def ruby_to_markdown(*args)
        any_args           = AnyArgs.new(args:                args,
                                         print_method_source: method(:print_method_source),
                                         caller:              caller,
                                         for_method:          __method__,
                                         method_creator:      method(:create_method_with_ruby_class))
        disable_processors = any_args.disable_processors
        ruby_source        = any_args.source_code

        RUBY_TO_MARKDOWN_PROCESSORS.each do |processor|
          options     = disable_processors.fetch(processor, :enabled)
          ruby_source =  if options == :enabled
            send(processor, ruby_source)
          elsif options.is_a?(Hash)
            send(processor, ruby_source, options)
          end
        end
        ruby_source
      end

      def comment_format(source_code=print_method_source, proc: false)
        gsub_replacement(source_code, { /^#(.*)/ => "</br>*(\\1)*</br>" }, proc: proc)
      end

      def remove_memoized_vars(source_code=print_method_source, proc: false)
        conversions = {
          /@[a-z][a-z0-9_]+ \|\|=?\s/ => "" # @memoized_vars ||=
        }
        gsub_replacement(source_code, conversions, proc: proc)
      end

      def nil_check_readable(source_code=print_method_source, proc: false)
        conversions = {
          ".nil?" => " is missing?"
        }
        gsub_replacement(source_code, conversions, proc: proc)
      end

      def elsif_to_else_if(source_code=print_method_source, proc: false)
        conversions = {
          "elsif" => "else if"
        }
        gsub_replacement(source_code, conversions, proc: proc)
      end

      def remove_colons(source_code=print_method_source, proc: false)
        conversions = {
          ":" => ''
        }
        gsub_replacement(source_code, conversions, proc: proc)
      end

      def ruby_operators_to_english(source_code=print_method_source, proc: false)
        conversions = {
          "&&"   => "and",
          ">="   => "is greater than or equal to",
          "<="   => "is less than or equal to",
          " < "  => " is less than ",
          " > "  => " is greater than ",
          " == " => " Equal to ",
          "||"   => "or"
        }

        gsub_replacement(source_code, conversions, proc: proc)
      end

      def readable_ruby_numbers(source_code=print_method_source, proc: -> (replacement, _) { ActiveSupport::NumberHelper.number_to_delimited(replacement) })
        source_code.gsub(/([0-9][0-9_]+[0-9]+)/) do |match|
          proc.call(eval(match), match)
        end
      end

      def convert_early_return_to_if_else(source_code=print_method_source, proc: false)
        conversions = {
          /(.+) if (.+)/   => "if \\2\n\\1\nend",
          /(.+) unless (.+)/ => "unless \\2\n\\1\nend"
        }
        gsub_replacement(source_code, conversions, proc: proc)
      end

      def pretty_early_return(source_code=print_method_source, proc: false)
        conversions = {
          /return (unless|if)/   => 'return nothing \1'
        }
        gsub_replacement(source_code, conversions, proc: proc)
      end

      def ternary_to_if_else(source_code=print_method_source, proc: false)
        conversions = {
          /(.*) \? (.*) \: (.*)/   =>  "if \\1\n\\2\nelse\n\\3\nend"
        }
        gsub_replacement(source_code, conversions, proc: proc)
      end

      # @param [String] title the name of the link
      # @param [String] link_ref the url with method anchor
      # @example format_link("MyLink", "path/to/it#method_name?")
      #   #=> "[MyLink](#path/to/it#method-name)"
      def format_link(title, link_ref)
        path, anchor   = *link_ref.to_s.split("#")
        formatted_path = [path, anchor.try!(:dasherize).try!(:delete, "?")].compact.join("#")
        "[#{title}](#{formatted_path})"
      end

      # @param [String] link_ref the url with method anchor
      # @example title_from_link"path/to/it#method_name?")
      #   #=> "[Method Name](#path/to/it#method-name)"
      def title_from_link(link_ref)
        [link_ref.split("/").last.split("#").last.to_s.humanize, link_ref]
      end

      UnimplementedMethod = Class.new(StandardError)
      # @param [Class, String, Pathname] klass_or_path
      #   1. String or Class representing a method reference
      #   2. Pathname representing the full path of the file location a method is defined
      # @param [String] title is the link display value
      # @return [String, Symbol] Creates link to a given generated markdown file or returns :non_project_location message.
      #   1. "[title](path/to/markdown/file.md#method-name)"
      #   2. :non_project_location
      def link_to_markdown(klass_or_path, title:, _ruby_class: ruby_class)
        if klass_or_path.is_a?(String) || klass_or_path.is_a?(Class) || klass_or_path.is_a?(Module)
          link_to_markdown_method_reference(method_reference: klass_or_path, title: title, ruby_class: _ruby_class)
        elsif klass_or_path.is_a?(Pathname)
          link_to_markdown_full_path(path: klass_or_path, title: title, ruby_class: _ruby_class)
        else
          raise ArgumentError, "invalid first arg given: #{klass_or_path} for #{__method__}"
        end
      end

      def link_to_markdown_method_reference(method_reference:, title:, ruby_class:)
        method = MarkdownRubyDocumentation::Method.create(method_reference, null_method: true, context: ruby_class)
        parts  = method.context_name.to_s.split("::").reject(&:blank?)
        path   = parts.map { |p| p.underscore }.join("/")
        path   = "#{path}.md#{method.type_symbol}#{method.name}"
        format_link title, MarkdownRubyDocumentation::GitHubLink::FileUrl.new(file_path: File.join(MarkdownRubyDocumentation::Generate.output_object.relative_dir, path)).to_s
      end

      def link_to_markdown_full_path(path:, title:, ruby_class:)
        if path.to_s.include?(MarkdownRubyDocumentation::Generate.load_path)
          relative_path    = path.to_s.gsub(MarkdownRubyDocumentation::Generate.load_path, "")
          const_nest, meth = relative_path.split("#")
          const            = const_nest.split("/").map(&:camelize).join("::")
          link_to_markdown_method_reference(method_reference: "#{const.gsub(".rb", "")}##{meth}", title: title, ruby_class: ruby_class)
        else
          :non_project_location
        end
      end

      class MethodLink
        RUBY_METHOD_REGEX = /(\b(?<!['"])[a-z_][a-z_0-9?!]*(?!['"]))/.freeze

        def initialize(match:,
                       call_on_title: :titleize,
                       method_to_class: {},
                       link_to_markdown:,
                       ruby_class:)
          @match            = match
          @ruby_class       = ruby_class
          @call_on_title    = call_on_title
          @method_to_class  = method_to_class
          @link_to_markdown = link_to_markdown
        end

        def link
          if constant_override
            constant_override_method_path
          else
            link = link_to_markdown.call(method_name, title: title, _ruby_class: method_owner)
            if link == :non_project_location
              match
            else
              link
            end
          end
        rescue UnimplementedMethod => e
          "[#{title}](##{match.downcase.dasherize.delete(" ").delete('?')})"
        end

        private

        attr_reader :match, :ruby_class, :call_on_title, :method_to_class, :link_to_markdown

        def title
          @title ||= if call_on_title
                       @call_on_title = [*call_on_title].compact
                       match.public_send(call_on_title.first, *call_on_title[1..-1])
                     else
                       match
                     end
        end

        def constant_override
          @constant_override ||= method_to_class[match.to_sym]
        end

        def method_name
          "##{match}"
        end

        def method_owner
          Method.create(method_name, context: ruby_class).to_proc.owner
        end

        def constant_override_method_path
          method_object = Method.create("##{match}", context: constant_override)
          link_to_markdown.call("#{method_object.context.name}##{method_object.name}", title: title)
        end
      end

      def methods_as_local_links(ruby_source,
                                 call_on_title: :titleize,
                                 method_to_class: {},
                                 proc: false)
        ruby_source.gsub(MethodLink::RUBY_METHOD_REGEX) do |match|
          if is_a_method_on_ruby_class?(match)
            replacement = MethodLink.new(match:            match,
                                         ruby_class:       ruby_class,
                                         call_on_title:    call_on_title,
                                         method_to_class:  method_to_class,
                                         link_to_markdown: method(:link_to_markdown)).link
            proc ? proc.call(replacement, match) : replacement
          else
            match
          end
        end
      end

      def constants_with_name_and_value(ruby_source, proc: false)
        ruby_source.gsub(/([A-Z]+[A-Z_0-9]+)/) do |match|
          begin
            value           = ruby_class.const_get(match)
            link            = "##{match.dasherize.downcase}"
            formatted_value = ConstantsPresenter.format(value)
            replacement     = format_link(formatted_value, link)
            proc ? proc.call(replacement, match, { value: value, link: link, formatted_value: formatted_value }) : replacement
          rescue NameError
            match
          end
        end
      end

      def question_mark_method_format(ruby_source, *)
        ruby_source.gsub(/(\b(?<!['"])\.[a-z_][a-z_0-9]+\?(?!['"]))/) do |match|
          " is #{match}".sub(".", "")
        end
      end

      def remove_end_keyword(ruby_source, *)
        ruby_source.gsub(/^[\s]*end\n?/, "")
      end

      def ruby_if_statement_to_md(ruby_source, proc: false)
        conversions = {
          /elsif(.*)/         => "* __Else If__\\1\n__Then__",
          /^\s?if(.*)/ => "* __If__\\1\n__Then__",
          /unless(.*)/        => "* __Unless__\\1\n__Then__",
          "else"              => "* __Else__"
        }
        gsub_replacement(ruby_source, conversions, proc: proc)
      end

      def ruby_case_statement_to_md(ruby_source, proc: false)
        conversions = {
          /case(.*)/ => "* __Given__\\1",
          /when(.*)/ => "* __When__\\1\n__Then__",
          "else"     => "* __Else__"
        }
        gsub_replacement(ruby_source, conversions, proc: proc)
      end

      def hash_to_markdown_table(hash, key_name:, value_name:)
        key_max_length   = [hash.keys.group_by(&:size).max.first, key_name.size + 1].max
        value_max_length = [hash.values.group_by { |v| v.try!(:size) || 1 }.max.first, value_name.size + 1].max
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
        parts      = array_headers.map { |header, pad_length=0| " #{header.ljust(pad_length-1)}" }
        bar        = parts.map(&:length).map { |length| ("-" * (length)) }.join("|")
        bar[-1]    = "|"
        header     = parts.join("|")
        header[-1] = "|"
        [("|" + header), ("|" + bar)].join("\n")
      end

      private

      def fetch_strings(source_code, &block)
        source_code.gsub(/["']?[a-z_A-Z?!0-9]*["']?/, &block)
      end

      def fetch_strings_that_contain_codes(source_code, &block)
        source_code.gsub(/["']?[a-z_A-Z?!0-9]*["']?/, &block)
      end

      def fetch_methods(source_code, &block)
        source_code.gsub(/(\b(?<!['"])[a-z_][a-z_0-9?!]*(?!['"]))/) do |match|
          block.call(match) if is_a_method_on_ruby_class?(match)
        end
      end

      def fetch_symbols(source_code, &block)
        source_code = source_code.gsub(/:[a-z_?!0-9]+/, &block)
        source_code = source_code.gsub(/[a-z_?!0-9]+:/, &block)
      end

      def is_a_method_on_ruby_class?(method)
        [*ruby_class.public_instance_methods, *ruby_class.private_instance_methods].include?(remove_quotes(method).to_sym)
      end

      def remove_quotes(string)
        string.gsub(/['|"]/, "")
      end

      def ruby_class
        @ruby_class || self
      end

      def create_method_with_ruby_class(method_reference)
        Method.create(method_reference, context: ruby_class)
      end

      def gsub_replacement(source_code, conversions, proc: false)
        conversions.each do |symbol, replacement|
          source_code = if proc
                          source_code.gsub(symbol, &proc.curry[replacement])
                        else
                          source_code.gsub(symbol, replacement)
                        end
        end
        source_code
      end
    end

    include CommentMacros
  end
end
