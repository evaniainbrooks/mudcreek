class Admin::OffersController < Admin::BaseController
  before_action :set_offer, only: [ :show, :update ]
  before_action :set_listing_has_accepted_offer, only: :show

  def index
    authorize(Offer)
    @filter_total = Offer.count
    @q = Offer.ransack(params[:q])
    scope = @q.result.includes(:listing, :user).order(created_at: :desc)
    @filter_count = scope.count
    @pagy, @offers = pagy(:keyset, scope)

    respond_to do |format|
      format.html
      format.turbo_stream do
        if params[:page].present?
          render turbo_stream: [
            turbo_stream.append("admin-offers-tbody", partial: "admin/offers/offer_row", collection: @offers, as: :offer),
            turbo_stream.replace("sentinel", partial: "admin/offers/sentinel", locals: { pagy: @pagy, q: params[:q] })
          ]
        else
          render :index, formats: [:html]
        end
      end
    end
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

  def set_listing_has_accepted_offer
    @listing_has_accepted_offer = @offer.listing.offers.accepted.where.not(id: @offer.id).exists?
  end
end
