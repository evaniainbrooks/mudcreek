class Admin::Lots::ListingPlaceholdersController < Admin::BaseController
  before_action :set_lot

  def destroy
    @lot.listing_placeholder.purge_later
    redirect_to admin_lots_path, notice: t(".notice", name: @lot.name)
  end

  private

  def set_lot
    @lot = Lot.find_by!(hashid: params[:lot_hashid])
    authorize(@lot, :update?)
  end
end
