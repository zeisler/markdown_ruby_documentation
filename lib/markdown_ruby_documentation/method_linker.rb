module MarkdownRubyDocumentation
  class MethodLinker

    attr_reader :text, :section_key, :root_path

    def initialize(section_key:, root_path:)

      @section_key = section_key
      @root_path   = root_path
    end

    def call(text=nil)
      @text        = text
      generate
    end

    private

    def generate
      text.scan(/(?<!\^`)`{1}([\w:_\.#?]*[^`\n])\`/).each do |r|
        r = r.first
        if r =~ /(\w*::\w*)+#[\w|\?]+/ # constant with an instance method
          parts = r.split("#")
          meths = parts[-1]
          const = parts[0]
          str = "[#{meths.titleize}](#{root_path}#{const.underscore.gsub("/", "-")}##{md_id meths})"
        elsif r =~ /\w*::\w*/ # is constant
          str = "[#{r.gsub("::", " ").titleize}](#{root_path}#{md_id r})"
        else # a method
          str = "[#{r.titleize}](##{md_id r})"
        end
        @text = text.gsub("^`#{r}`", str)
      end
      text
    end

    def md_id(str)
      str.downcase.dasherize.delete(" ").delete('?')
    end
  end
end
