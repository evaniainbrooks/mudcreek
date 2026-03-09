class Admin::AuctionsController < Admin::BaseController
  before_action :set_auction, only: %i[show edit update destroy]

  def index
    authorize(Auction)
    @q = Auction.ransack(params[:q])
    @auctions = @q.result.includes({ listings: :lot }, :address).order(:starts_at)
    @auction = Auction.new
  end

  def show
    @auction_listings_count = @auction.auction_listings.count
    @auction_registrations_count = @auction.auction_registrations.count
    scope = @auction.auction_listings.includes(:listing).order(:position, :id)
    @pagy, @auction_listings = pagy(:keyset, scope)

    if @auction.reconciled?
      @report_listings = @auction.auction_listings
        .includes(:listing, bids: { auction_registration: :user })
        .order(:position)
    end

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.append("auction-listings-tbody",
            partial: "admin/auctions/auction_listing_row",
            collection: @auction_listings,
            locals: { auction: @auction },
            as: :auction_listing),
          turbo_stream.replace("auction-listings-sentinel",
            partial: "admin/auctions/sentinel",
            locals: { pagy: @pagy, auction: @auction })
        ]
      end if params[:page].present?
    end
  end

  def new
    @auction = Auction.new
    @auction.build_address
    if Current.tenant.default_terms_and_conditions.attached?
      @auction.terms_and_conditions.attach(Current.tenant.default_terms_and_conditions.blob)
    end
    authorize(@auction)
  end

  def create
    @auction = Auction.new(timezone_aware_auction_params)
    authorize(@auction)

    if @auction.save
      schedule_reconciler(@auction)
      redirect_to admin_auction_path(@auction), notice: "Auction was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @auction.build_address unless @auction.address
  end

  def update
    @auction.poster.purge_later if params[:remove_poster].present?
    @auction.terms_and_conditions.purge_later if params[:remove_terms_and_conditions].present?
    if @auction.update(timezone_aware_auction_params)
      schedule_reconciler(@auction) if @auction.saved_change_to_ends_at?
      redirect_to admin_auction_path(@auction), notice: "Auction was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @auction.destroy!
    redirect_to admin_auctions_path, notice: "Auction was successfully deleted."
  end

  private

  def set_auction
    @auction = Auction.with_attached_poster.with_attached_terms_and_conditions.find_by!(hashid: params[:hashid])
    authorize(@auction)
  end

  def auction_params
    p = params.require(:auction).permit(
      :name, :admin_email_address, :starts_at, :ends_at, :end_time_stagger_interval, :bidding_extension, :published, :reconciled, :auto_approve, :poster, :terms_and_conditions, :description, :timezone,
      address_attributes: %i[id street_address city province postal_code country _destroy]
    )
    p.delete(:poster) if p[:poster].blank?
    p.delete(:terms_and_conditions) if p[:terms_and_conditions].blank?
    p
  end

  def timezone_aware_auction_params
    p = auction_params
    tz = ActiveSupport::TimeZone[p[:timezone].presence || @auction&.timezone || "UTC"] || Time.zone
    p[:starts_at] = tz.parse(p[:starts_at]) if p[:starts_at].present?
    p[:ends_at]   = tz.parse(p[:ends_at])   if p[:ends_at].present?
    p
  end

  def schedule_reconciler(auction)
    return unless auction.ends_at.present?

    tz = ActiveSupport::TimeZone[auction.timezone] || Time.zone
    run_at = auction.auction_listings.minimum(:ends_at)&.in_time_zone(tz) ||
             auction.ends_at.in_time_zone(tz)

    AuctionReconcilerJob.set(wait_until: run_at).perform_later(auction)
  end
end
