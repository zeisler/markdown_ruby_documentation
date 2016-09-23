module MarkdownRubyDocumentation
  class RelativeLinkConverter
    attr_reader :text, :root_path, :subject

    def initialize(subject:)
      @root_path = root_path
      @subject   = subject
    end

    def call(text=nil)
      @text = text
      generate
    end

    def generate
      text.scan(/\[[\w?\-_!0-9 ]*\]\((.*?)\)/).each do |r|
        link = r.first

        if link.include?(path.to_s)
          @text = text.gsub(link, create_relative_link(link))
        end
      end
      text
    end

    def path
      @path ||= begin
        method = MarkdownRubyDocumentation::Method.create(subject.name, null_method: true, context: Kernel)
        parts  = method.context_name.to_s.split("::").reject(&:blank?)
        path   = parts.map { |p| p.underscore }.join("/")
        path   = "#{path}.md#{method.type_symbol}#{method.name}"
        MarkdownRubyDocumentation::GitHubLink::FileUrl.new(file_path: File.join(MarkdownRubyDocumentation::Generate.output_object.relative_dir, path)).to_s
      end
    end

    def create_relative_link(link)
      if link.include?("#")
        "#" + link.split("#").last
      else
        link
      end
    end
  end
end
