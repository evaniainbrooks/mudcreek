class Admin::Dashboard::NavSectionComponent < ViewComponent::Base
  def initialize(title:, links:)
    @title = title
    @links = links
  end

  def self.sections(view)
    view.admin_nav_sections
  end
end
