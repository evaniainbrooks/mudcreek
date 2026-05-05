class AuctionRegistrationsController < ApplicationController
  include AuctionFeatureGated
  before_action :set_auction

  def create
    if AuctionRegistration.exists?(auction: @auction, user: Current.user)
      redirect_to auction_path(@auction), alert: t(".alert")
      return
    end

    @registration = AuctionRegistration.new(auction: @auction, user: Current.user)

    if @registration.save
      AuctionMailer.registration_pending(@registration).deliver_later unless @auction.auto_approve?
      notice = if @auction.auto_approve?
        t(".notice_approved")
      else
        t(".notice_pending")
      end
      redirect_to auction_path(@auction), notice: notice
    else
      redirect_to auction_path(@auction), alert: @registration.errors.full_messages.to_sentence
    end
  end

  private

  def set_auction
    @auction = Auction.find_by!(hashid: params[:auction_hashid], published: true)
  end
end
