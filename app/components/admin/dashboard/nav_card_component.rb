class Admin::Dashboard::NavCardComponent < ViewComponent::Base
  def initialize(label:, icon:, path:)
    @label = label
    @icon = icon
    @path = path
  end

  def background_color
    hue = @label.bytes.inject(0) { |sum, b| sum * 31 + b } % 360
    "hsl(#{hue}, 60%, 93%)"
  end
end
