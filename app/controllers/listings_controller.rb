class ListingsController < ApplicationController
  allow_unauthenticated_access

  def show
    @listing = Listing.where(published: true)
                      .with_rich_text_description
                      .with_attached_images
                      .with_attached_videos
                      .find(params[:id])
  end

  def index
    scope = Listing.where(published: true).with_rich_text_description.with_attached_images.with_attached_videos.order(id: :asc)
    @pagy, @listings = pagy(:keyset, scope)

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.append("listings", partial: "listings/listing", collection: @listings, as: :listing),
          turbo_stream.replace("sentinel", partial: "listings/sentinel", locals: { pagy: @pagy })
        ]
      end
    end
  end
end
