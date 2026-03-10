class Admin::Dashboard::NavSectionComponent < ViewComponent::Base
  def initialize(title:, links:)
    @title = title
    @links = links
  end
end
