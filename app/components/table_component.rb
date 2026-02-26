class TableComponent < ViewComponent::Base
  Column = Data.define(:header, :sort_attr, :html_class, :typed, :block)

  def initialize(rows:, ransack_query: nil)
    @rows = rows
    @ransack_query = ransack_query
    @columns = []
  end

  def with_column(header, sort_attr: nil, html_class: nil, &block)
    @columns << Column.new(header:, sort_attr:, html_class:, typed: false, block:)
    self
  end

  def with_value_column(header, sort_attr: nil, html_class: nil, &block)
    @columns << Column.new(header:, sort_attr:, html_class:, typed: true, block:)
    self
  end
end
