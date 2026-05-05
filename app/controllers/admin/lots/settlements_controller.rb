class Admin::Lots::SettlementsController < Admin::BaseController
  before_action :set_lot_and_settlement

  def show
  end

  def pay
    authorize(@settlement || Settlement.new, :update?)
    return redirect_to admin_lot_settlement_path(@lot), alert: t(".alert") unless @settlement

    @lot.update!(
      state:               :paid,
      paid_at:             Time.current,
      payout_amount_cents: @settlement.net_payout_cents
    )

    LotMailer.payout_sent(@lot).deliver_later
    redirect_to admin_lot_settlement_path(@lot), notice: t(".notice")
  end

  private

  def set_lot_and_settlement
    @lot        = Lot.find_by!(hashid: params[:lot_hashid])
    @settlement = @lot.settlement
    authorize(@settlement || Settlement.new, :show?)
  end
end
