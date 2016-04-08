module MarkdownRubyDocumentation
  class WriteMarkdownToDisk

    attr_reader :dir

    def initialize(dir:)
      @dir = dir
    end

    def call(name:, text:)
      name = name.gsub(dir, "").underscore
      path = File.join(dir, name)
      FileUtils.mkdir_p(path.split("/").tap { |p| p.pop }.join("/"))
      File.open("#{path}.md", "w").write(text)
    end
  end
end
