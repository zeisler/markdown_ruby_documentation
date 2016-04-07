module MarkdownRubyDocumentation
  class GitHubProject
    class << self
      def url
        `git config --get remote.origin.url`
      end

      def root_path
        `git rev-parse --show-toplevel`
      end
    end
  end
end
