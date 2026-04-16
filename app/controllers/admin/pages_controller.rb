class Admin::PagesController < Admin::BaseController
  before_action :set_page, only: %i[edit update destroy]

  def index
    authorize(Page)
    @pages = Page.includes(:parent).order(:position, :id)
  end

  def new
    @page = Page.new(parent_id: params[:parent_id])
    authorize(@page)
  end

  def edit
  end

  def create
    @page = Page.new(page_params)
    authorize(@page)

    if @page.save
      if params[:create_navbar_item] == "1"
        NavbarItem.create!(
          title: @page.title,
          path: "/#{@page.slug}",
          position: NavbarItem.maximum(:position).to_i + 1
        )
      end
      redirect_to admin_pages_path, notice: "Page was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    @page.hero_image.purge_later        if params[:remove_hero_image].present?
    @page.left_column_image.purge_later  if params[:remove_left_column_image].present?
    @page.right_column_image.purge_later if params[:remove_right_column_image].present?

    if @page.update(page_params)
      redirect_to admin_pages_path, notice: "Page was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @page.destroy!
    redirect_to admin_pages_path, notice: "Page was successfully deleted."
  end

  private

  def set_page
    @page = Page.find_by!(slug: params[:id])
    authorize(@page)
  end

  def page_params
    params.require(:page).permit(:title, :slug, :icon, :body, :published, :position,
                                 :parent_id, :meta_title, :meta_description,
                                 :hero_image, :left_column_image, :right_column_image,
                                 widgets_attributes: [ :id, :type, :position, :gallery_id,
                                                       :location_id, :inquiry_form_id,
                                                       :qr_code_id, :listing_id, :_destroy ])
  end

end
