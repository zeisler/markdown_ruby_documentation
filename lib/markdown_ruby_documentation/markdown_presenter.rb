module MarkdownRubyDocumentation
  class MarkdownPresenter

    attr_reader :title, :items, :title_key, :summary

    def initialize(title:, items: nil, summary:, title_key:, skip_blanks: true)
      @title       = title
      @items       = items
      @summary     = summary
      @title_key   = title_key
      @skip_blanks = skip_blanks
    end

    def call(items=nil)
      @items ||= items
      <<-MD
# #{title}
#{summary}

#{present_items}
      MD
    end

    private

    def present_items
      items.reject { |k, v| v.blank? }.map do |name, text|
        %[## #{name.to_s.titleize}\n#{text}]
      end.join("\n\n")
    end

  end
end
