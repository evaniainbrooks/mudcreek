class ListingsController < ApplicationController
  allow_unauthenticated_access

  def show
    @listing = Listing.where(published: true)
                      .with_rich_text_description
                      .with_attached_images
                      .with_attached_videos
                      .with_attached_documents
                      .includes(lot: { listing_placeholder_attachment: :blob })
                      .find(params[:id])
    @cart_item = Current.user&.cart_items&.find_by(listing_id: @listing.id)
  end

  def index
    @categories = Listings::Category.order(:name)
    @category_id = params[:category_id].presence

    scope = Listing.where(published: true).with_rich_text_description.with_attached_images.with_attached_videos.includes(lot: { listing_placeholder_attachment: :blob }).order(position: :asc, id: :asc)
    scope = scope.where(id: Listings::CategoryAssignment.where(listings_category_id: @category_id).select(:listing_id)) if @category_id
    @pagy, @listings = pagy(:keyset, scope)

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.append("listings", partial: "listings/listing", collection: @listings, as: :listing),
          turbo_stream.replace("sentinel", partial: "listings/sentinel", locals: { pagy: @pagy, category_id: @category_id })
        ]
      end
    end
  end
end
