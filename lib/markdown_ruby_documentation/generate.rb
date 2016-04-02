module MarkdownRubyDocumentation
  class Generate
    # @param [Class] subject a ruby class to generate documentation from.
    # @param [Array<Symbols>] methods a list of instance method that are to be documented
    # @param [String] project_root the path to the root of your git project
    # @param [String] github_link the GitHub base link to your project
    # @param [Pathname, String, File] file where the  markdown is saved.
    def initialize(subject:, methods: subject.public_instance_methods(false), project_root:, github_link:, file:)
      @subject      = subject
      @methods      = methods
      @github_link  = github_link
      @project_root = project_root
      @file_path    = file
    end

    def call
      file.write run_pipeline(string_pipeline, run_pipeline(methods_pipeline).to_s)
      file.close
      self
    end

    def file
      @file ||= case file_path
               when String, Pathname
                 File.open(File.join(file_path.path), 'w')
               when File, Tempfile
                 file_path
               end
    end

    private
    attr_reader :subject, :project_root, :github_link, :file_path

    def methods_pipeline
      [
        TemplateParser.new(subject, @methods),
        GitHubLink.new(subject: subject, root: project_root, base_url: github_link),
        MarkdownPresenter.new(title: subject.name.titleize, title_key: section_key),
      ]
    end

    def string_pipeline
      [
        MethodLinker.new(section_key: section_key, root_path: "./"),
      ]
    end

    def run_pipeline(pipeline, last_result=nil)
      last_result ||= pipeline.shift.call
      pipeline.each do |pipe|
        last_result = pipe.call(last_result)
      end
      last_result
    end

    def section_key
      subject.name.underscore.gsub("/", "-")
    end
  end
end
