class CartsController < ApplicationController
  def show
    @cart_items = Current.user.cart_items.includes(:listing).order(:created_at)
    @subtotal = Money.new(@cart_items.sum { |item| item.listing.price_cents })
  end
end
