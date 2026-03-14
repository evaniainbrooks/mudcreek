class Admin::Lots::SettlementsController < Admin::BaseController
  before_action :set_lot_and_settlement

  def show
  end

  private

  def set_lot_and_settlement
    @lot        = Lot.find(params[:lot_id])
    @settlement = @lot.settlement
    authorize(@settlement || Settlement.new, :show?)
  end
end
