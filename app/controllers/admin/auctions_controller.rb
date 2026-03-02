class Admin::AuctionsController < Admin::BaseController
  before_action :set_auction, only: %i[show edit update destroy]

  def index
    authorize(Auction)
    @auctions = Auction.includes(:listings, :address).order(:starts_at)
    @auction = Auction.new
  end

  def show
    @auction_listings = @auction.auction_listings.includes(:listing).order(:position)
  end

  def new
    @auction = Auction.new
    @auction.build_address
    authorize(@auction)
  end

  def create
    @auction = Auction.new(auction_params)
    authorize(@auction)

    if @auction.save
      redirect_to admin_auction_path(@auction), notice: "Auction was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @auction.build_address unless @auction.address
  end

  def update
    @auction.poster.purge_later if params[:remove_poster].present?
    @auction.cover_photo.purge_later if params[:remove_cover_photo].present?
    if @auction.update(auction_params)
      redirect_to admin_auction_path(@auction), notice: "Auction was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @auction.destroy!
    redirect_to admin_auctions_path, notice: "Auction was successfully deleted."
  end

  private

  def set_auction
    @auction = Auction.with_attached_poster.with_attached_cover_photo.find(params[:id])
    authorize(@auction)
  end

  def auction_params
    p = params.require(:auction).permit(
      :name, :starts_at, :ends_at, :published, :reconciled, :poster, :cover_photo, :description,
      address_attributes: %i[id street_address city province postal_code country _destroy]
    )
    %i[poster cover_photo].each { |key| p.delete(key) if p[key].blank? }
    p
  end
end
