class CartDeliveryMethodsController < ApplicationController
  def create
    method = DeliveryMethod.where(active: true).find_by(id: params[:delivery_method_id])

    if method.nil?
      redirect_to cart_path, alert: t(".alert")
    else
      session[:delivery_method_id] = method.id
      redirect_to cart_path, notice: t(".notice", name: method.name)
    end
  end

  def destroy
    session.delete(:delivery_method_id)
    redirect_to cart_path, notice: t(".notice")
  end
end
