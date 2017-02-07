module MarkdownRubyDocumentation
  class Generate
    # @param [Array[Class, String]] subjects ruby classes to generate documentation from and file location.
    # @param [Module] erb_methods must contain #link_to_markdown and contain any additional methods for comment ERB
    # @param [Proc] output_object given name: and text: for use in saving the the files.
    # @param [String] load_path
    # @param [Hash] parallel_config - example { in_threads: 7 } - defaults to 2
    class << self
      def run(
        subjects:,
        erb_methods: DefaultErbMethods,
        output_object:,
        load_path:,
        parallel_config: {})
        self.output_object = output_object
        self.load_path     = load_path
        erb_methods_class  = Class.new
        erb_methods_class.extend TemplateParser::CommentMacros
        erb_methods_class.extend erb_methods
        TemplateParser::CommentMacros.include erb_methods
        subject_classes = subjects.map { |h| h.fetch(:class) }
        left_padding(subject_classes)
        progressbar(subject_classes)
        progressbar.title = "Compiling Markdown".ljust(left_padding)
        batches           = subjects.each_slice(parallel_config.fetch(:in_threads, 2))
        threads           = []
        batches.each do |batch|
          threads << Thread.new(batch) do |(_batch)|
          Array[_batch].flatten.map do |subject|
            progressbar.title = subject.fetch(:class).name.ljust(left_padding)
            Page.new(subject_class:       subject.fetch(:class),
                     subject_location:    subject.fetch(:file_path).to_s,
                       output_object:     output_object,
                       erb_methods_class: erb_methods_class,
                       load_path:         load_path).call.tap { progressbar.increment }
            end
          end
        end
        pages             = threads.flat_map(&:value)
        return_value      = pages.each_with_object({}) do |page, hash|
          name_parts      = page.subject.name.split("::")
          name            = name_parts.pop
          namespace       = name_parts.join("::")
          hash[namespace] ||= {}
          hash[namespace].merge!({ name => page })
          hash
        end
        progressbar.title = "Markdown Documentation Compilation Complete".ljust(left_padding)
        progressbar.finish
        return_value
      end

      def progressbar(subjects=nil)
        @progressbar ||= ProgressBar.create(title: "Compiling Markdown".ljust(left_padding(subjects)), total: subjects.count+ 1)
      end

      def left_padding(subjects=nil)
        @left_padding ||= subjects.map(&:name).group_by(&:size).max.first
      end
      attr_accessor :load_path, :output_object
    end

    class Page
      attr_reader :subject, :subject_location, :output_object, :erb_methods_class, :load_path

      def initialize(subject_class:,
                     subject_location:,
                     methods: [],
                     load_path:,
                     output_object:,
                     erb_methods_class:)
        initialize_methods(methods, subject_class, subject_location)
        @erb_methods_class = erb_methods_class
        @subject           = subject_class
        @subject_location  = subject_location
        methods            = methods
        @methods           = methods
        @load_path         = load_path
        @output_object     = output_object
      end

      def call
        methods_pipes = run_pipeline(methods_pipeline)
        text          = run_pipeline(string_pipeline, methods_pipes)
        output_object.call(name: subject.name,
                           text: text)
        self
      end

      private
      def initialize_methods(methods, subject, subject_location)
        if methods.empty?
          all_instance_and_class_methods(methods, subject, subject_location)
        else
          methods.map! { |method| method.is_a?(Symbol) ? InstanceMethod.new("#{subject.name}##{method}", context: subject, file_path: subject_location) : method }
        end
      end

      def all_instance_and_class_methods(methods, subject, subject_location)
        native_instance_methods = (subject.instance_methods(false) - Object.instance_methods(false)).concat(subject.private_instance_methods(false) - Object.private_instance_methods(false))
        super_instance_methods  = (subject.instance_methods(true) - Object.instance_methods(true)).concat(subject.private_instance_methods(true) - Object.private_instance_methods(true)) - native_instance_methods
        native_klass_methods    = (subject.methods(false) - Object.methods(false)).concat(subject.private_methods(false) - Object.private_methods(false))
        super_klass_methods     = (subject.methods(true) - Object.methods(true)).concat(subject.private_methods(true) - Object.private_methods(true)) - native_klass_methods
        methods.concat super_instance_methods.reverse.map { |method| InstanceMethod.new("#{subject.name}##{method}", context: subject, visibility: :super, file_path: subject_location) }
        methods.concat native_instance_methods.map { |method| InstanceMethod.new("#{subject.name}##{method}", context: subject, visibility: :native, file_path: subject_location) }
        methods.concat super_klass_methods.map { |method| ClassMethod.new("#{subject.name}.#{method}", context: subject, visibility: :super, file_path: subject_location) }
        methods.concat native_klass_methods.map { |method| ClassMethod.new("#{subject.name}.#{method}", context: subject, visibility: :native, file_path: subject_location) }
      end

      def methods_pipeline
        [
          TemplateParser.new(subject, @methods),
          RejectBlankMethod,
          GitHubLink.new(subject: subject),
          ConstantsPresenter.new(subject),
          ClassLevelComment.new(subject),
          MarkdownPresenter.new(summary: summary, title_key: section_key),
        ]
      end

      def string_pipeline
        [
          MethodLinker.new(section_key: section_key, root_path: "./"),
          RelativeLinkConverter.new(subject: subject),
        ]
      end

      def summary
        @summary ||= Summary.new(subject: subject, erb_methods_class: erb_methods_class)
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
end
