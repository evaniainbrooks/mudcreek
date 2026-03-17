class Profiles::OrdersController < Profiles::BaseController
  def show
    @orders = Current.user.orders.includes(:order_items).order(created_at: :desc)
  end
end
