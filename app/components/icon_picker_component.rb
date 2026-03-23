class IconPickerComponent < ViewComponent::Base
  def initialize(form:, field:, **input_options)
    @form = form
    @field = field
    @input_options = input_options
  end

  def icons
    BOOTSTRAP_ICON_NAMES
  end

  def current_value
    @form.object.public_send(@field).to_s
  end
end
