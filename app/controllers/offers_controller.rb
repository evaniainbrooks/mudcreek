class OffersController < ApplicationController
  before_action :set_listing

  def create
    @offer = @listing.offers.new(
      user: Current.user,
      amount_cents: (params.dig(:offer, :amount).to_f * 100).round,
      message: params.dig(:offer, :message).presence
    )

    if @offer.save
      redirect_to listing_path(@listing), notice: "Your offer has been submitted."
    else
      redirect_to listing_path(@listing), alert: @offer.errors.full_messages.to_sentence
    end
  end

  private

  def set_listing
    @listing = Listing.find_by!(hashid: params[:listing_hashid])
  end
end
