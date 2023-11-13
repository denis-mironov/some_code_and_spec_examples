# Overrides the limited_nodes method to apply custom pagination.
# If a query receives the pagination argument, then our custom pagination is performed,
# otherwise the default pagination is used.

module Extensions
  class CustomActiveRecordRelationConnection < GraphQL::Pagination::ActiveRecordRelationConnection
    def limited_nodes
      if context[:pagination].present?
        @limited_nodes ||= custom_paginated_nodes
      else
        super
      end
    end

    private

    def custom_paginated_nodes
      limit = find_limit
      page = context.fetch(:pagination).page
      offset = context.fetch(:pagination).offset

      result = items.limit(limit)

      if page.present?
        result = result.offset(page_offset(page, limit))
      elsif offset.present?
        result = result.offset(offset)
      end

      result
    end

    def find_limit
      max_page_size = context.schema.default_max_page_size
      limit = context.fetch(:pagination).limit

      limit.present? && limit <= max_page_size ? limit : max_page_size
    end

    def page_offset(page, limit)
      (page - 1) * limit
    end
  end
end
