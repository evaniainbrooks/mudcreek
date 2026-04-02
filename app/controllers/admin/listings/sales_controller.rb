class Admin::Listings::SalesController < Admin::BaseController
  before_action :set_listing

  def create
    result = RecordManualSaleService.call(
      listing:          @listing,
      quantity:         sale_params[:quantity].to_i,
      unit_price_cents: (sale_params[:unit_price].to_f * 100).round,
      buyer_name:       sale_params[:buyer_name],
      buyer_email:      sale_params[:buyer_email],
      notes:            sale_params[:notes]
    )

    if result.success?
      redirect_to admin_order_path(result.order), notice: "Manual sale recorded."
    else
      redirect_to admin_listing_path(@listing, anchor: "inventory-pane"), alert: result.error
    end
  end

  private

  def set_listing
    @listing = Listing.find_by!(hashid: params[:listing_hashid])
    authorize(@listing, :update?)
  end

  def sale_params
    params.require(:manual_sale).permit(:quantity, :unit_price, :buyer_name, :buyer_email, :notes)
  end
end
