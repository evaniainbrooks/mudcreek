class CartItemsController < ApplicationController
  def create
    Current.user.cart_items.create(listing_id: params[:listing_id])
    redirect_back fallback_location: root_path,
      notice: helpers.safe_join([ "Added to cart. ", helpers.link_to("View cart", cart_path) ])
  end

  def destroy
    cart_item = Current.user.cart_items.find(params[:id])
    cart_item.destroy
    redirect_back fallback_location: cart_path, notice: "Removed from cart."
  end
end
