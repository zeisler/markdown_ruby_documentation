module MarkdownRubyDocumentation
  class MarkdownPresenter

    attr_reader :items, :title_key, :summary

    def initialize(items: nil, summary:, title_key:, skip_blanks: true)
      @items         = items
      @summary       = summary
      @title_key     = title_key
      @skip_blanks   = skip_blanks
      @present_items = []
    end

    def call(items=nil)
      @items ||= items
      return "" if nothing_to_display?
      md = ["# #{summary.title}", "#{summary.summary}\n".gsub(/\n\n\n/, "\n\n"), instances_methods, class_methods, "#{null_methods}\n".gsub(/\n\n\n/, "\n\n")].join("\n").gsub(/[\n]+\Z/, "\n\n")
      other_types!
      md
    end

    private

    def item_types
      @item_types ||= items.group_by { |_, hash| hash[:method_object].class.name }
    end

    def instances_methods
      @instance_methods ||= item_types.delete("MarkdownRubyDocumentation::InstanceMethod")  || {}
      @instance_methods.map do |name, hash|
        %[## #{name.to_s.titleize}\n#{hash[:text]}] unless hash[:text].blank?
      end.join("\n\n")
    end

    def class_methods
      @class_methods ||= item_types.delete("MarkdownRubyDocumentation::ClassMethod")  || {}
      @class_methods.map do |name, hash|
        %[## #{name.to_s.titleize}\n#{hash[:text]}] unless hash[:text].blank?
      end.join("\n\n")
    end

    def null_methods
      @null_methods ||= item_types.delete("MarkdownRubyDocumentation::NullMethod") || {}
      md = @null_methods.map do |name, hash|
        %[### #{name.to_s.titleize}\n#{hash[:text]}] unless hash[:text].blank?
      end.join("\n\n")
      if md.blank?
        ""
      else
        "## Reference Values\n" << md
      end
    end

    def other_types!
      raise "Unhandled methods types: #{item_types}" unless item_types.empty?
    end

    def nothing_to_display?
      [instances_methods, class_methods, null_methods].all?(&:empty?)
    end
  end
end
