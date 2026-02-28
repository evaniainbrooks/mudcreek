class CartDiscountsController < ApplicationController
  def create
    code = DiscountCode.find_by(key: params[:discount_code]&.upcase&.strip)

    if code.nil?
      redirect_to cart_path, alert: "Discount code not found."
    elsif !code.active?
      redirect_to cart_path, alert: "This discount code is not currently active."
    else
      session[:discount_code_id] = code.id
      redirect_to cart_path, notice: "Discount code \"#{code.key}\" applied."
    end
  end

  def destroy
    session.delete(:discount_code_id)
    redirect_to cart_path, notice: "Discount code removed."
  end
end
