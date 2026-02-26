class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Method

  before_action :resume_session
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :cart_item_count

  private

  def cart_item_count
    Current.user&.cart_items&.count || 0
  end
end
