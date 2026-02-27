class Admin::LotsController < Admin::BaseController
  before_action :set_lot, only: [ :update, :destroy ]

  def index
    authorize(Lot)
    @lot = Lot.new
    @users = User.order(:email_address)
    @lots = Lot.includes(:owner, :listings).with_attached_listing_placeholder.order(:name)
  end

  def create
    @lot = Lot.new(lot_params)
    authorize(@lot)
    if @lot.save
      redirect_to admin_lots_path, notice: "Lot \"#{@lot.name}\" was successfully created."
    else
      @users = User.order(:email_address)
      @lots = Lot.includes(:owner, :listings).with_attached_listing_placeholder.order(:name)
      render :index, status: :unprocessable_entity
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
    @lot = Lot.find(params[:id])
    authorize(@lot)
  end

  def lot_params
    params.require(:lot).permit(:name, :number, :owner_id, :listing_placeholder)
  end
end
