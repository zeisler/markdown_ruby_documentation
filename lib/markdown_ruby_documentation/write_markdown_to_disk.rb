module MarkdownRubyDocumentation
  class WriteMarkdownToDisk

    attr_reader :dir, :skip_if_blank, :relative_dir

    def initialize(dir:, skip_if_blank: false, relative_dir:)
      @dir           = dir
      @skip_if_blank = skip_if_blank
      @relative_dir  = relative_dir
    end

    def call(name:, text:)
      return if skip_save?(text, name)
      name = name.gsub(dir, "").underscore
      file = "#{name}.md"
      path = File.join(dir, file)

      return if file_exists_with?(text, path)
      write_file(path, text)
    end

    private

    def file_exists_with?(text, path)
      File.exist?(path) && Digest::MD5.new.update(File.open(path).read) == Digest::MD5.new.update(text)
    end

    def write_file(path, text)
      FileUtils.mkdir_p(path.split("/").tap { |p| p.pop }.join("/"))
      File.open(path, "w").write(text)
    end

    def skip_save?(text, _name)
      if skip_if_blank
        return true if Array(text.split("\n")[2..-1]).all?(&:blank?)
      end
    end
  end
end
