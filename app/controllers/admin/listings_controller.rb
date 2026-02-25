class Admin::ListingsController < Admin::BaseController
  before_action :set_listing, only: %i[show edit update destroy]

  def index
    @q = Listing.ransack(params[:q])
    scope = @q.result.includes(:owner).order(id: :asc)
    @pagy, @listings = pagy(:keyset, scope)
  end

  def show
  end

  def new
    @listing = Listing.new
  end

  def edit
  end

  def create
    @listing = Listing.new(listing_params)

    if @listing.save
      redirect_to admin_listing_path(@listing), notice: "Listing was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @listing.update(listing_params)
      redirect_to admin_listing_path(@listing), notice: "Listing was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @listing.destroy!
    redirect_to admin_listings_path, notice: "Listing was successfully deleted."
  end

  private

  def set_listing
    @listing = Listing.find(params[:id])
  end

  def listing_params
    params.require(:listing).permit(:name, :description, :price, :owner_id)
  end
end
