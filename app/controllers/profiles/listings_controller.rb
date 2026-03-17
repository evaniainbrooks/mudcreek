class Profiles::ListingsController < Profiles::BaseController
  LISTINGS_PER_PAGE = 12

  def show
    @pagy, @purchased_listings = pagy(purchased_listings_scope, limit: LISTINGS_PER_PAGE)

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.append("purchased-listings", partial: "profiles/purchased_listing", collection: @purchased_listings, as: :listing),
          turbo_stream.replace("purchased-listings-sentinel", partial: "profiles/purchased_listings_sentinel", locals: { pagy: @pagy })
        ]
      end
    end
  end

  private

  def purchased_listings_scope
    Listing
      .joins(order_items: :order)
      .where(orders: { user: Current.user, status: :paid })
      .with_attached_images
      .includes(:lot)
      .distinct
      .order(id: :desc)
  end
end
