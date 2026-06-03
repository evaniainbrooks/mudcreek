class Admin::LotsController < Admin::BaseController
  before_action :set_lot, only: [ :show, :update, :destroy ]

  def index
    authorize(Lot)
    @lot = Lot.new
    @users = User.activated.order(:email_address)
    @filter_total = Lot.count
    @q = Lot.ransack(params[:q])
    @lots = @q.result.includes(:owner, :listings, :settlement).with_attached_listing_placeholder.order(:name)
    @filter_count = @lots.size
  end

  def show
    @lot.build_address unless @lot.address
    @users = User.activated.order(:email_address)
    @listings = @lot.listings.includes(:owner, :categories, :gallery).order(:name)
    @settlement = @lot.settlement
    @settlement_line_items = @settlement&.settlement_line_items&.order(:created_at)
  end

  def create
    @lot = Lot.new(lot_params)
    authorize(@lot)
    if @lot.save
      redirect_to admin_lot_path(@lot), notice: t(".notice", name: @lot.name)
    else
      @users = User.activated.order(:email_address)
      @q = Lot.ransack(nil)
      @lots = @q.result.includes(:owner, :listings, :settlement).with_attached_listing_placeholder.order(:name)
      @filter_total = Lot.count
      @filter_count = @lots.size
      flash.now[:alert] = @lot.errors.full_messages.to_sentence
      render :index, status: :unprocessable_content
    end
  end

  def update
    if @lot.update(lot_params)
      redirect_to admin_lot_path(@lot), notice: t(".notice")
    else
      @lot.build_address unless @lot.address
      @users = User.activated.order(:email_address)
      @listings = @lot.listings.includes(:owner, :categories, :gallery).order(:name)
      @settlement = @lot.settlement
      @settlement_line_items = @settlement&.settlement_line_items&.order(:created_at)
      flash.now[:alert] = @lot.errors.full_messages.to_sentence
      render :show, status: :unprocessable_content
    end
  end

  def destroy
    @lot.destroy!
    redirect_to admin_lots_path, notice: t(".notice", name: @lot.name)
  end

  private

  def set_lot
    @lot = Lot.find_by!(hashid: params[:hashid])
    authorize(@lot)
  end

  def lot_params
    p = params.require(:lot).permit(:name, :number, :owner_id, :listing_placeholder, :admin_notes, :commission_rate, :seller_fee, :state, :show_attribution,
      address_attributes: %i[id street_address city province postal_code country _destroy])
    p.delete(:listing_placeholder) if p[:listing_placeholder].blank?
    p
  end
end
