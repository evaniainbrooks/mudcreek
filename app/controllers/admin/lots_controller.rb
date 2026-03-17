class Admin::LotsController < Admin::BaseController
  before_action :set_lot, only: [ :update, :destroy ]

  def index
    authorize(Lot)
    @lot = Lot.new
    @users = User.order(:email_address)
    @filter_total = Lot.count
    @q = Lot.ransack(params[:q])
    @lots = @q.result.includes(:owner, :listings, :settlement).with_attached_listing_placeholder.order(:name)
    @filter_count = @lots.size
  end

  def create
    @lot = Lot.new(lot_params)
    authorize(@lot)
    if @lot.save
      redirect_to admin_lots_path, notice: "Lot \"#{@lot.name}\" was successfully created."
    else
      @users = User.order(:email_address)
      @q = Lot.ransack(nil)
      @lots = @q.result.includes(:owner, :listings, :settlement).with_attached_listing_placeholder.order(:name)
      @filter_total = Lot.count
      @filter_count = @lots.size
      render :index, status: :unprocessable_content
    end
  end

  def update
    @lot.update(lot_params)
    @users = User.order(:email_address)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to admin_lots_path }
    end
  end

  def destroy
    @lot.destroy!
    redirect_to admin_lots_path, notice: "Lot \"#{@lot.name}\" was successfully deleted."
  end

  private

  def set_lot
    @lot = Lot.find_by!(hashid: params[:hashid])
    authorize(@lot)
  end

  def lot_params
    params.require(:lot).permit(:name, :number, :owner_id, :listing_placeholder, :admin_notes, :commission_rate, :seller_fee, :state)
  end
end
