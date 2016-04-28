module MarkdownRubyDocumentation
  class AnyArgs
    attr_reader :disable_processors, :source_code

    def initialize(args:, print_method_source:, caller:, for_method:, method_creator:)
      @args                = args
      @print_method_source = print_method_source
      @caller              = caller
      @for_method          = for_method
      @method_creator      = method_creator
      call
    end

    private

    attr_reader :args, :print_method_source, :caller, :for_method, :method_creator

    def call
      if args.first.is_a?(Hash)
        when_hash_first(args.first)
      elsif args.first.is_a?(String)
        when_string_first(args)
      elsif args.empty?
        when_no_args
      else
        raise ArgumentError, "Incorrect arguments given: #{for_method}(#{args})", caller
      end
    end

    def when_hash_first(options)
      @disable_processors = options
      if options.has_key?(:method_reference)
        @source_code        = print_method_source.call(method_creator.call(options[:method_reference]))
      else
        @source_code        = print_method_source.call
      end
    end

    def when_string_first(args)
      @source_code        = args.first
      @disable_processors = args[1] || {}
    end

    def when_no_args
      @disable_processors = {}
      @source_code        = print_method_source.call
    end
  end
end
