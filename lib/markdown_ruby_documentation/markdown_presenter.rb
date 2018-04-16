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
      md = ["# #{summary.title}", "#{summary.summary}\n".gsub(/\n\n\n/, "\n\n"), class_level_comment, instances_methods, class_methods, "#{null_methods}\n".gsub(/\n\n\n/, "\n\n")]
             .reject(&:empty?)
             .join("\n")
             .gsub(/[\n]{3,}/, "\n\n")
             .gsub(/[\n]+\Z/, "\n\n")
      other_types!
      md
    end

    private

    def item_types
      @item_types ||= items.group_by { |_, hash| hash[:method_object].class.name }
    end

    def class_level_comment
      @class_level_comment ||= (items.delete(:class_level_comment) || {})

      if @class_level_comment[:text]
        "#{@class_level_comment[:text]}\n"
      else
        ""
      end
    end

    def instances_methods
      @instance_methods ||= method_presenters("MarkdownRubyDocumentation::InstanceMethod")
    end

    def class_methods
      @class_methods ||= method_presenters("MarkdownRubyDocumentation::ClassMethod")
    end

    def null_methods
      @null_methods ||= begin
        md = method_presenters("MarkdownRubyDocumentation::NullMethod", "###")
        if md.blank?
          ""
        else
          "\n## Reference Values\n" << md
        end
      end
    end

    def method_presenters(type, heading="##")
      type_methods = item_types.delete(type) || []
      order_by_location(type_methods).map do |(name, hash)|
        %[#{heading} #{name.to_s.titleize}\n#{hash[:text]}] unless hash[:text].blank?
      end.join("\n\n")
    end

    def order_by_location(items)
      items.sort_by do |(name, hash)|
        hash[:method_object].source_location rescue name # NullMethod has no source_location
      end
    end

    def other_types!
      raise "Unhandled methods types: #{item_types}" unless item_types.empty?
    end

    def nothing_to_display?
      [class_level_comment, instances_methods, class_methods, null_methods].all?(&:empty?)
    end
  end
end
