class Admin::GalleriesController < Admin::BaseController
  before_action :set_gallery, only: [:destroy]

  def index
    authorize(Gallery)
    q_params = params[:q].present? ? params[:q] : { listing_id_null: "1" }
    @q = Gallery.ransack(q_params)
    scope = @q.result
      .with_attached_photos
      .with_attached_videos
      .with_attached_documents
      .includes(:listing)
      .order(:name)
    @filter_total = Gallery.count
    @filter_count = scope.count
    @galleries = scope
  end

  def destroy
    @gallery.destroy!
    redirect_to admin_galleries_path, notice: "Gallery was successfully deleted."
  end

  private

  def set_gallery
    @gallery = Gallery.find(params[:id])
    authorize(@gallery)
  end
end
