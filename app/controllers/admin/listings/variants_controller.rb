class Admin::Listings::VariantsController < Admin::BaseController
  before_action :set_listing

  def create
    Listings::VariantGenerator.call(listing: @listing)
    redirect_to edit_admin_listing_path(@listing), notice: t(".notice")
  end

  private

  def set_listing
    @listing = Listing.find_by!(hashid: params[:listing_hashid])
    authorize(@listing, :update?)
  end
end
