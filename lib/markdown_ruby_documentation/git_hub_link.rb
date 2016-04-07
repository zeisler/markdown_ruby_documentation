module MarkdownRubyDocumentation
  class GitHubLink

    attr_reader :subject, :base_url, :root

    def initialize(subject:, base_url: GitHubProject.url, root: GitHubProject.root_path)
      @subject  = subject
      @methods  = methods
      @base_url = base_url
      @root = root
    end

    def call(hash)
      hash.each_with_object({}) do |(meth, value),h|
        file, lineno = subject.instance_method(meth).source_location
        h[meth] = "#{value}\n\n[show on github](#{link(file, lineno)})"
      end
    end

    def link(file, lineno)
      "#{base_url}blob/#{blob(file)}#{relative_path(file)}#L#{lineno}"
    end

    def blob(file)
      v = `git ls-files -s #{relative_path(file)}`
      return "master" if v
      v
    end

    def relative_path(file)
      file.sub(root, "")
    end
  end
end
