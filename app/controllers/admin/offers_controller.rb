class Admin::OffersController < Admin::BaseController
  before_action :set_offer, only: [ :show, :update ]

  def index
    authorize(Offer)
    @q = Offer.ransack(params[:q])
    scope = @q.result.includes(:listing, :user).order(created_at: :desc)
    @pagy, @offers = pagy(:keyset, scope)
  end

  def show
  end

  def update
    state = params[:state].presence_in(Offer.states.keys)
    return redirect_to admin_offer_path(@offer), alert: "Invalid state." unless state

    @offer.update!(state: state)
    redirect_to admin_offer_path(@offer), notice: "Offer #{state}."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to admin_offer_path(@offer), alert: e.message
  end

  private

  def set_offer
    @offer = Offer.find(params[:id])
    authorize(@offer)
  end
end
