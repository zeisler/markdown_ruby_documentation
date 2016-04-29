module MarkdownRubyDocumentation
  class WriteMarkdownToDisk

    attr_reader :dir, :skip_if_blank, :relative_dir

    def initialize(dir:, skip_if_blank: false, relative_dir:)
      @dir           = dir
      @skip_if_blank = skip_if_blank
      @relative_dir = relative_dir
    end

    def call(name:, text:)
      return if skip_save?(text, name)
      name = name.gsub(dir, "").underscore
      path = File.join(dir, name)
      FileUtils.mkdir_p(path.split("/").tap { |p| p.pop }.join("/"))
      File.open("#{path}.md", "w").write(text)
    end

    private

    def skip_save?(text, name)
      if skip_if_blank
        if Array(text.split("\n")[2..-1]).all? { |line| line.blank? }
          return true
        end
      end
    end
  end
end
