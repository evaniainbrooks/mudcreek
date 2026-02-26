class TableCellComponent < ViewComponent::Base
  # Register a custom renderer for a class.
  # The block is instance_exec'd inside the component, so helpers, content_tag, etc. are all available.
  #
  # Example:
  #   TableCellComponent.register(User) { |user| helpers.mail_to(user.email_address) }
  #
  def self.register(klass, &renderer)
    renderers[klass] = renderer
  end

  def self.renderers
    @renderers ||= {}
  end

  def initialize(value:, html_class: nil)
    @value = value
    @html_class = html_class
  end

  def call
    content_tag(:td, class: @html_class) { cell_content }
  end

  private

  def cell_content
    renderer = self.class.renderers[@value.class]
    return instance_exec(@value, &renderer) if renderer
    case @value
    when Money
      helpers.humanized_money_with_symbol(@value)
    when Time, ActiveSupport::TimeWithZone, DateTime
      content_tag(:time, @value.to_fs(:long),
        datetime: @value.iso8601,
        title: @value.to_fs(:long),
        class: "text-muted")
    when Date
      content_tag(:time, @value.to_fs(:long), datetime: @value.iso8601, class: "text-muted")
    when TrueClass
      content_tag(:span, "Yes", class: "badge text-bg-success")
    when FalseClass
      content_tag(:span, "No", class: "badge text-bg-secondary")
    when NilClass
      content_tag(:span, "—", class: "text-muted")
    when String
      if @value.match?(URI::MailTo::EMAIL_REGEXP)
        helpers.mail_to(@value)
      elsif @value.match?(/\A\+?[\d\s\-().]{7,20}\z/)
        helpers.link_to(@value, "tel:#{@value.gsub(/[^\d+]/, "")}")
      else
        h(@value)
      end
    else
      h(@value.to_s)
    end
  end
end
