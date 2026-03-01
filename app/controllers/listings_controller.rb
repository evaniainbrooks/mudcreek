class ListingsController < ApplicationController
  allow_unauthenticated_access

  def show
    @listing = Listing.where(published: true)
                      .with_rich_text_description
                      .with_attached_images
                      .with_attached_videos
                      .with_attached_documents
                      .includes(lot: { listing_placeholder_attachment: :blob })
                      .find_by!(hashid: params[:hashid])
    @cart_item = Current.user&.cart_items&.find_by(listing_id: @listing.id)
  end

  def index
    @categories = Listings::Category.order(:name)
    @tab = params[:tab].presence_in(%w[on_sale sold]) || "on_sale"
    @category_hashid = params[:category_id].presence
    category = @category_hashid && Listings::Category.find_by(hashid: @category_hashid)

    scope = Listing.where(published: true, state: @tab).with_rich_text_description.with_attached_images.with_attached_videos.includes(:rental_rate_plans, lot: { listing_placeholder_attachment: :blob }).order(position: :asc, id: :asc)
    scope = scope.where(id: Listings::CategoryAssignment.where(listings_category_id: category.id).select(:listing_id)) if category
    @pagy, @listings = pagy(:keyset, scope)

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.append("listings", partial: "listings/listing", collection: @listings, as: :listing),
          turbo_stream.replace("sentinel", partial: "listings/sentinel", locals: { pagy: @pagy, category_id: @category_hashid, tab: @tab })
        ]
      end
    end
  end
end
