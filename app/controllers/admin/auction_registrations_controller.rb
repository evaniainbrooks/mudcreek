class Admin::AuctionRegistrationsController < Admin::BaseController
  before_action :set_registration, only: :update

  def index
    authorize(AuctionRegistration)
    @filter_total = AuctionRegistration.count
    @q = AuctionRegistration.ransack(params[:q])
    scope = @q.result.includes(:user, :auction).order(created_at: :desc, id: :desc)
    @filter_count = scope.count
    @pagy, @registrations = pagy(:keyset, scope)

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.append("admin-auction-registrations-tbody",
            partial: "admin/auction_registrations/auction_registration_row",
            collection: @registrations,
            as: :auction_registration),
          turbo_stream.replace("auction-registrations-sentinel",
            partial: "admin/auction_registrations/sentinel",
            locals: { pagy: @pagy, q: params[:q] })
        ]
      end
    end
  end

  def update
    @registration.update(registration_params)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to admin_auction_registrations_path }
    end
  end

  private

  def set_registration
    @registration = AuctionRegistration.find(params[:id])
    authorize(@registration)
  end

  def registration_params
    params.require(:auction_registration).permit(:state, :admin_notes)
  end
end
