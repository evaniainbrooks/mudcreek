class CartDiscountsController < ApplicationController
  allow_unauthenticated_access

  def create
    code = DiscountCode.find_by(key: params[:discount_code]&.upcase&.strip)

    if code.nil?
      redirect_to cart_path, alert: t(".alert_not_found")
    elsif !code.active?
      redirect_to cart_path, alert: t(".alert_inactive")
    else
      session[:discount_code_id] = code.id
      redirect_to cart_path, notice: t(".notice", key: code.key)
    end
  end

  def destroy
    session.delete(:discount_code_id)
    redirect_to cart_path, notice: t(".notice")
  end
end
