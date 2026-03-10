class Admin::Dashboard::NavCardComponent < ViewComponent::Base
  def initialize(label:, icon:, path:)
    @label = label
    @icon = icon
    @path = path
  end
end
