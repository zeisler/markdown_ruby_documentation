module MarkdownRubyDocumentation
  class GitHubLink
    attr_reader :subject, :base_url, :root

    def initialize(subject:, base_url: GitHubProject.url, root: GitHubProject.root_path)
      @subject  = subject
      @base_url = base_url
      @root     = root
    end

    def call(hash)
      hash.each do |name, values|
        hash[name][:text] = "#{values[:text]}\n\n[show on github](#{create_link(name: name, method_object: values[:method_object], context: subject)})"
      end
    end

    def create_link(name: nil, method_object: nil, context: Kernel)
      if name && method_object.nil?
        method_object = Method.create("##{name}", context: context)
      end
      MethodUrl.new(subject: subject, base_url: base_url, root: root, method_object: method_object).to_s
    end

    class FileUrl
      attr_reader :file_path, :base_url, :root

      def initialize(file_path:, base_url: GitHubProject.url, root: GitHubProject.root_path)
        @file_path = file_path
        @base_url  = base_url
        @root      = root
      end

      def to_s
        link(file_path)
      end

      def to_pathname
        Pathname(to_s)
      end

      def link(file, lineno=nil)
        str = File.join(base_url, "blob", blob(file), relative_path(file))
        unless lineno.nil?
          str << "#L#{lineno}"
        end
        str.chomp.gsub("https://github.com///github.com/", "https://github.com/")
      end

      def blob(file)
        GitHubProject.branch
      end

      def relative_path(file)
        file.sub(root, "")
      end
    end

    class MethodUrl
      attr_reader :base_url, :method_object, :subject, :root

      def initialize(subject:, method_object:, base_url: GitHubProject.url, root: GitHubProject.root_path)
        @subject       = subject
        @base_url      = base_url
        @root          = root
        @method_object = method_object
      end

      def to_s
        file, lineno = method_object.source_location
        FileUrl.new(file_path: file, base_url: base_url, root: root).link(file, lineno)
      end
    end
  end
end
