module MarkdownRubyDocumentation
  class GitHubLink
    attr_reader :subject, :base_url, :root

    def initialize(subject:, base_url: GitHubProject.url, root: GitHubProject.root_path)
      @subject  = subject
      @base_url = base_url
      @root     = root
    end

    def call(hash)
      hash.each_with_object({}) do |(meth, value), h|
        h[meth] = "#{value}\n\n[show on github](#{create_link(meth)})"
      end
    end

    def create_link(meth)
      Url.new(subject: subject, base_url: base_url, root: root, method_object: Method.create("##{meth}")).to_s
    end

    class Url
      attr_reader :base_url, :method_object, :subject, :root

      def initialize(subject:, method_object:, base_url: GitHubProject.url, root: GitHubProject.root_path)
        @subject       = subject
        @base_url      = base_url
        @root          = root
        @method_object = method_object
      end

      def to_s
        file, lineno = subject.public_send(method_object.type, method_object.name).source_location
        link(file, lineno)
      end

      def link(file, lineno)
        "#{base_url}/blob/#{blob(file)}#{relative_path(file)}#L#{lineno}".chomp
      end

      def blob(file)
        v = `git ls-files -s #{relative_path(file)}`
        return "master" if v
        v
      end

      def relative_path(file)
        file.sub(root.chomp, "")
      end
    end
  end
end
