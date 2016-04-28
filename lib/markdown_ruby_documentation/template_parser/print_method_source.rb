module MarkdownRubyDocumentation
  class PrintMethodSource
    def initialize(method:)
      @method_object = method
    end

    def print
      method_object.to_proc
        .source
        .split("\n")[1..-2]
        .map(&:lstrip)
        .join("\n")
    end

    private

    attr_reader :method_object
  end
end
