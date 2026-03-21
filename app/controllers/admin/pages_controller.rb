class Admin::PagesController < Admin::BaseController
  before_action :set_page, only: %i[edit update destroy]

  def index
    authorize(Page)
    @pages = Page.order(:position, :id)
  end

  def new
    @page = Page.new
    authorize(@page)
  end

  def edit
  end

  def create
    @page = Page.new(page_params)
    authorize(@page)

    if @page.save
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
    params.require(:page).permit(:title, :slug, :icon, :body, :published, :show_in_nav, :show_in_footer, :position,
                                 :meta_title, :meta_description,
                                 :hero_image, :left_column_image, :right_column_image)
  end
end
