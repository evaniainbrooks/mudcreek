class Admin::Lots::ListingPlaceholderController < Admin::BaseController
  before_action :set_lot

  def destroy
    @lot.listing_placeholder.purge_later
    redirect_to admin_lots_path, notice: "Placeholder image removed from \"#{@lot.name}\"."
  end

  private

  def set_lot
    @lot = Lot.find(params[:lot_id])
    authorize(@lot, :update?)
  end
end
