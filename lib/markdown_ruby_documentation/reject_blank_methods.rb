module MarkdownRubyDocumentation
  module RejectBlankMethod
    def self.call(methods)
      methods.reject do |_, hash|
        hash[:text].nil? || hash[:text].blank?
      end
    end
  end
end
