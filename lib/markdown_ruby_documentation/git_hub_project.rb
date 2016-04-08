module MarkdownRubyDocumentation
  class GitHubProject
    class << self
      def git_url
        `git config --get remote.origin.url`
      end

      def url
        "https://github.com/#{git_url.split(":").last.gsub(".git", "")}".chomp
      end

      def root_path
        `git rev-parse --show-toplevel`
      end
    end
  end
end
