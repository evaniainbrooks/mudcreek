class Admin::GalleriesController < Admin::BaseController
  before_action :set_gallery, only: %i[edit update destroy]

  def index
    authorize(Gallery)
    q_params = params[:q].present? ? params[:q] : { listing_id_null: "1" }
    @listing_id_null = q_params[:listing_id_null]
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

  def new
    @gallery = Gallery.new
    authorize(@gallery)
  end

  def create
    @gallery = Gallery.new(gallery_params)
    authorize(@gallery)

    if @gallery.save
      redirect_to admin_galleries_path, notice: t(".notice")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @gallery.update(gallery_params)
      redirect_to admin_galleries_path, notice: t(".notice")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @gallery.destroy!
    redirect_to admin_galleries_path, notice: t(".notice")
  end

  private

  def set_gallery
    @gallery = Gallery.find(params[:id])
    authorize(@gallery)
  end

  def gallery_params
    params.require(:gallery).permit(:name, :description, photos: [], videos: [], documents: [])
  end
end
