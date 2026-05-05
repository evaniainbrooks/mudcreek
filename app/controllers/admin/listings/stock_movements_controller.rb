class Admin::Listings::StockMovementsController < Admin::BaseController
  before_action :set_listing
  before_action :set_movement, only: [ :destroy ]

  def create
    @movement = @listing.stock_movements.build(movement_params.merge(kind: :stock_in, reason: :acquisition))

    if @movement.save
      redirect_to admin_listing_path(@listing, anchor: "inventory-pane"), notice: t(".notice")
    else
      redirect_to admin_listing_path(@listing, anchor: "inventory-pane"),
        alert: @movement.errors.full_messages.to_sentence
    end
  end

  def destroy
    @movement.destroy
    redirect_to admin_listing_path(@listing, anchor: "inventory-pane"), notice: t(".notice")
  end

  private

  def set_listing
    @listing = Listing.find_by!(hashid: params[:listing_hashid])
    authorize(@listing, :update?)
  end

  def set_movement
    @movement = @listing.stock_movements.find(params[:id])
  end

  def movement_params
    params.require(:listings_stock_movement).permit(:quantity, :unit_price, :transacted_on, :notes)
  end
end
