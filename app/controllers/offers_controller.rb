class OffersController < ApplicationController
  allow_unauthenticated_access only: [:create]

  before_action :set_listing

  def create
    if @listing.rental?
      redirect_to listing_path(@listing), alert: t(".alert")
      return
    end

    @offer = @listing.offers.new(
      user: Current.user,
      amount_cents: (params.dig(:offer, :amount).to_f * 100).round,
      message: params.dig(:offer, :message).presence,
      guest_name: params.dig(:offer, :guest_name).presence,
      guest_email: params.dig(:offer, :guest_email).presence,
      guest_phone: params.dig(:offer, :guest_phone).presence
    )

    if @offer.save
      ListingMailer.offer_received(@offer).deliver_later
      redirect_to listing_path(@listing), notice: t(".notice")
    else
      redirect_to listing_path(@listing), alert: @offer.errors.full_messages.to_sentence
    end
  end

  private

  def set_listing
    @listing = Listing.find_by!(hashid: params[:listing_hashid])
  end
end
