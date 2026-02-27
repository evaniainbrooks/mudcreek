class EmptyStateComponent < ViewComponent::Base
  def initialize(message:, icon: nil, link_text: nil, link_url: nil, link_class: "btn btn-primary")
    @message = message
    @icon = icon
    @link_text = link_text
    @link_url = link_url
    @link_class = link_class
  end
end
