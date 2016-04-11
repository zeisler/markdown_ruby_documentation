module MarkdownRubyDocumentation
  class GitHubProject
    class << self
      def git_url
        `git config --get remote.origin.url`.chomp
      end

      def url
        "https://github.com/#{git_url.split(":").last.gsub(".git", "")}".chomp
      end

      def root_path
        `git rev-parse --show-toplevel`.chomp
      end

      def set_branch(branch)
        @branch = branch
      end

      def branch
        @branch || current_branch
      end

      def current_branch
        `git rev-parse --abbrev-ref HEAD`.chomp
      end
    end
  end
end
