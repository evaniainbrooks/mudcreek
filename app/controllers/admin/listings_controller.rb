class Admin::ListingsController < Admin::BaseController
  before_action :set_listing, only: %i[show edit update destroy]

  def index
    authorize(Listing)
    @categories = Listings::Category.order(:name)
    @lots = Lot.order(:number)
    @q = Listing.ransack(params[:q])
    scope = @q.result.includes(:owner, :categories, :lot).order(id: :asc)
    @pagy, @listings = pagy(:keyset, scope)
  end

  def show
  end

  def new
    @listing = Listing.new
    @categories = Listings::Category.order(:name)
    @lots = Lot.order(:name)
  end

  def edit
    @categories = Listings::Category.order(:name)
    @lots = Lot.order(:name)
  end

  def create
    @listing = Listing.new(listing_params)

    if @listing.save
      redirect_to admin_listing_path(@listing), notice: "Listing was successfully created."
    else
      @categories = Listings::Category.order(:name)
      @lots = Lot.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @listing.update(listing_params)
      redirect_to admin_listing_path(@listing), notice: "Listing was successfully updated."
    else
      @categories = Listings::Category.order(:name)
      @lots = Lot.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @listing.destroy!
    redirect_to admin_listings_path, notice: "Listing was successfully deleted."
  end

  private

  def set_listing
    @listing = Listing.includes(:categories).with_attached_images.with_attached_videos.with_attached_documents.find(params[:id])
    authorize(@listing)
  end

  def listing_params
    p = params.require(:listing).permit(:name, :description, :price, :acquisition_price, :quantity, :tax_exempt, :owner_id, :lot_id, :published, images: [], videos: [], documents: [], category_ids: [])
    %i[images videos documents].each { |key| p.delete(key) if Array(p[key]).all?(&:blank?) }
    p
  end
end
