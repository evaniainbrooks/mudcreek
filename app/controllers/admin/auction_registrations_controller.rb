class Admin::AuctionRegistrationsController < Admin::BaseController
  def index
    authorize(AuctionRegistration)
    @q = AuctionRegistration.ransack(params[:q])
    scope = @q.result.includes(:user, :auction).order(created_at: :desc, id: :desc)
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
end
