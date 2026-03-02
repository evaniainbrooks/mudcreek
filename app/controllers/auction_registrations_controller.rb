class AuctionRegistrationsController < ApplicationController
  before_action :set_auction

  def create
    if AuctionRegistration.exists?(auction: @auction, user: Current.user)
      redirect_to auction_path(@auction), alert: "You are already registered for this auction."
      return
    end

    @registration = AuctionRegistration.new(auction: @auction, user: Current.user)

    if @registration.save
      redirect_to auction_path(@auction), notice: "You're registered! You'll receive an email once your registration is approved."
    else
      redirect_to auction_path(@auction), alert: @registration.errors.full_messages.to_sentence
    end
  end

  private

  def set_auction
    @auction = Auction.find_by!(hashid: params[:auction_hashid], published: true)
  end
end
