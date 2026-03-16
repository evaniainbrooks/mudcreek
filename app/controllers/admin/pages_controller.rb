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
    @page = Page.find(params[:id])
    authorize(@page)
  end

  def page_params
    params.require(:page).permit(:title, :slug, :body, :published, :show_in_nav, :show_in_footer, :position)
  end
end
