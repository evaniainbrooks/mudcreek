class Admin::Listings::AcquisitionsController < Admin::BaseController
  before_action :set_listing
  before_action :set_acquisition, only: [ :destroy ]

  def create
    @acquisition = @listing.acquisitions.build(acquisition_params)

    if @acquisition.save
      redirect_to admin_listing_path(@listing, anchor: "inventory-pane"), notice: "Acquisition recorded."
    else
      redirect_to admin_listing_path(@listing, anchor: "inventory-pane"),
        alert: @acquisition.errors.full_messages.to_sentence
    end
  end

  def destroy
    @acquisition.destroy
    redirect_to admin_listing_path(@listing, anchor: "inventory-pane"), notice: "Acquisition removed."
  end

  private

  def set_listing
    @listing = Listing.find_by!(hashid: params[:listing_hashid])
    authorize(@listing, :update?)
  end

  def set_acquisition
    @acquisition = @listing.acquisitions.find(params[:id])
  end

  def acquisition_params
    params.require(:listings_acquisition).permit(:quantity, :unit_price, :acquired_on, :notes)
  end
end
