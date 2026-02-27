class Admin::Listings::CategoriesController < Admin::BaseController
  before_action :set_category, only: [ :destroy ]

  def index
    authorize(Listings::Category)
    @category = Listings::Category.new
    @categories = Listings::Category.includes(:category_assignments).order(:name)
  end

  def create
    @category = Listings::Category.new(category_params)
    authorize(@category)
    if @category.save
      redirect_to admin_listings_categories_path, notice: "Category \"#{@category.name}\" was successfully created."
    else
      @categories = Listings::Category.includes(:category_assignments).order(:name)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @category.destroy!
    redirect_to admin_listings_categories_path, notice: "Category \"#{@category.name}\" was successfully deleted."
  end

  private

  def set_category
    @category = Listings::Category.find(params[:id])
    authorize(@category)
  end

  def category_params
    params.require(:listings_category).permit(:name, :description)
  end
end
