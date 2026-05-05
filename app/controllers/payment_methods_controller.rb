class PaymentMethodsController < ApplicationController
  before_action :set_service

  def create
    card = @service.create_card(source_id: params.require(:source_id))
    @service.set_default_card(card_id: card.id) if Current.user.default_square_card_id.blank?
    redirect_to edit_profile_path(anchor: "payment-methods"), notice: t(".notice", last_4: card.last_4)
  rescue SquareCustomerService::Error => e
    redirect_to edit_profile_path(anchor: "payment-methods"), alert: e.message
  end

  def set_default
    @service.set_default_card(card_id: params[:id])
    redirect_to edit_profile_path(anchor: "payment-methods"), notice: t(".notice")
  end

  def destroy
    @service.disable_card(card_id: params[:id])
    redirect_to edit_profile_path(anchor: "payment-methods"), notice: t(".notice")
  rescue SquareCustomerService::Error => e
    redirect_to edit_profile_path(anchor: "payment-methods"), alert: e.message
  end

  private

  def set_service
    @service = SquareCustomerService.new(Current.user)
  end
end
