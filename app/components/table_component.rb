class TableComponent < ViewComponent::Base
  Column = Data.define(:header, :sort_attr, :html_class, :typed, :block)

  attr_reader :columns

  def initialize(rows:, ransack_query: nil, row_data: nil, tbody_id: nil, tbody_data: {})
    @rows = rows
    @ransack_query = ransack_query
    @columns = []
    @row_data = row_data
    @tbody_id = tbody_id
    @tbody_data = tbody_data
  end

  def with_column(header, sort_attr: nil, html_class: nil, &block)
    @columns << Column.new(header:, sort_attr:, html_class:, typed: false, block:)
    self
  end

  def with_value_column(header, sort_attr: nil, html_class: nil, &block)
    @columns << Column.new(header:, sort_attr:, html_class:, typed: true, block:)
    self
  end

  def with_footer_row(&block)
    @footer_row = block
    self
  end

  def footer_row = @footer_row
end
