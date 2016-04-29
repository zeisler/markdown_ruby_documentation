module MarkdownRubyDocumentation
  class ClassLevelComment
    attr_reader :subject
    include TemplateParser::Parsing
    def initialize(subject)
      @subject = subject
    end

    def call(interface)
      _method = interface.reject do |_, meth|
        meth[:method_object].is_a?(NullMethod)
      end.first
      if _method
        filename, lineno = _method[1][:method_object].to_proc.source_location
        comment = extract_dsl_comment(strip_comment_hash(comment(filename, lineno)+"\n"))
        interface[:class_level_comment] = { text: comment }
      end
      interface
    end

    def comment(filename, lineno)
      method_to_top_of_file = File.read(filename).split("\n")[0..(lineno-1)]
      subject_start_line = find_start_of_subject(method_to_top_of_file, filename)
      extract_last_comment(method_to_top_of_file[0..(subject_start_line-1)].reverse).reverse.join("\n")
    end

    def find_start_of_subject(method_to_top_of_file, filename)
      method_to_top_of_file.each_with_index do |line, index|
        if line =~ /#{subject.class.to_s.downcase} #{subject.name.split("::").last}/
          return index
        end
      end
      puts /#{subject.class} #{subject.name.split("::").last}/
      puts method_to_top_of_file
      raise "class #{subject.name} not found in #{filename}"
    end

    def extract_last_comment(lines)
      buffer = []

      lines.each do |line|
        # Add any line that is a valid ruby comment,
        # but clear as soon as we hit a non comment line.
        if line =~ /^\s*#/
          buffer << line.lstrip
        else
          return buffer
        end
      end

      buffer
    end
  end
end
