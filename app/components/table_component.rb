class TableComponent < ViewComponent::Base
  include Ransack::Helpers::FormHelper
  Column = Data.define(:header, :sort_attr, :html_class, :block)

  def initialize(rows:, ransack_query: nil)
    @rows = rows
    @ransack_query = ransack_query
    @columns = []
  end

  def with_column(header, sort_attr: nil, html_class: nil, &block)
    @columns << Column.new(header:, sort_attr:, html_class:, block:)
    self
  end
end
