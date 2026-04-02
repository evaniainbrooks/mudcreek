class Admin::ListingsController < Admin::BaseController
  before_action :set_listing, only: %i[show edit update destroy]

  def index
    authorize(Listing)
    @categories = Listings::Category.order(:name)
    @lots = Lot.order(:number)
    @auctions = Auction.unreconciled.order(:name)
    @filter_total = Listing.count
    @q = Listing.ransack(params[:q])
    scope = @q.result.includes(:owner, :categories, :lot, :auction_listing).order(position: :asc, id: :asc)
    @filter_count = scope.count
    @pagy, @listings = pagy(:keyset, scope)

    respond_to do |format|
      format.html
      format.turbo_stream do
        if params[:page].present?
          render turbo_stream: [
            turbo_stream.append("admin-listings-tbody", partial: "admin/listings/listing_row", collection: @listings, as: :listing),
            turbo_stream.replace("sentinel", partial: "admin/listings/sentinel", locals: { pagy: @pagy, q: params[:q] })
          ]
        else
          render :index, formats: [ :html ]
        end
      end
    end
  end

  def show
    @offers       = @listing.sale? ? @listing.offers.includes(:user).order(created_at: :desc) : []
    @movements = @listing.sale? ? @listing.stock_movements.order(transacted_on: :desc, created_at: :desc) : []
    if @listing.rental?
      @rental_rate_plans = @listing.rental_rate_plans.order(:position)
      @rental_bookings   = @listing.rental_bookings
        .where("expires_at > ?", Time.current)
        .includes(cart_item: :user)
        .order(:start_at)
    end
    if @listing.auction_listing
      @bids = @listing.auction_listing.bids
        .includes(auction_registration: :user)
        .order(amount_cents: :desc, created_at: :desc)
    end
    load_form_collections
  end

  def new
    @listing = Listing.new(delivery_method_set_id: Current.tenant.default_delivery_method_set_id)
    authorize(@listing)
    load_form_collections
    if params[:property_set_id].present?
      property_set = Listings::PropertySet.find_by(id: params[:property_set_id])
      property_set&.properties&.order(:position)&.each_with_index do |prop, idx|
        @listing.properties.build(name: prop.name, value: prop.value, position: idx + 1)
      end
    end
  end

  def edit
    load_form_collections
  end

  def create
    @listing = Listing.new(listing_params)
    authorize(@listing)

    if @listing.save
      redirect_to admin_listing_path(@listing), notice: "Listing was successfully created."
    else
      load_form_collections
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @listing.update(listing_params)
      redirect_to admin_listing_path(@listing), notice: "Listing was successfully updated."
    else
      load_form_collections
      render :edit, status: :unprocessable_content
    end
  end

  def reorder
    authorize(Listing)
    listing = Listing.find(params[:id])
    listing.insert_at(params[:position].to_i)
    head :ok
  end

  def destroy
    @listing.destroy!
    redirect_to admin_listings_path, notice: "Listing was successfully deleted."
  end

  private

  def load_form_collections
    @categories          = Listings::Category.order(:name)
    @lots                = Lot.order(:name)
    @property_sets       = Listings::PropertySet.order(:name)
    @delivery_method_sets = Listings::DeliveryMethodSet.order(:name)
  end

  def set_listing
    @listing = Listing.includes(:categories, :properties, auction_listing: :auction).with_attached_images.with_attached_videos.with_attached_documents.find_by!(hashid: params[:hashid])
    authorize(@listing)
  end

  def listing_params
    base = %i[name description price quantity unlimited_quantity sku tax_exempt delivery_method_set_id owner_id lot_id published pricing_type show_video_as_poster]
    base.unshift(:listing_type) if action_name == "create"
    p = params.require(:listing).permit(*base, images: [], videos: [], documents: [], category_ids: [],
      rental_rate_plans_attributes: [:id, :label, :duration_minutes, :price, :_destroy],
      properties_attributes: [:id, :name, :value, :icon, :position, :_destroy],
      address_attributes: [:id, :street_address, :city, :province, :postal_code, :country, :address_type],
      options_attributes: [:id, :name, :position, :_destroy,
        option_values_attributes: [:id, :value, :position, :_destroy]],
      variants_attributes: [:id, :quantity, :price_cents, :sku, :_destroy])
    %i[images videos documents].each { |key| p.delete(key) if Array(p[key]).all?(&:blank?) }
    p
  end
end
