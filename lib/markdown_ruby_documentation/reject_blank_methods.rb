module MarkdownRubyDocumentation
  module RejectBlankMethod
    def self.call(methods)
      methods.reject { |_, t| t.nil? || t.blank? }
    end
  end
end
