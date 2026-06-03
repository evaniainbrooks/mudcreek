class Admin::NavbarItemsController < Admin::BaseController
  before_action :set_navbar_item, only: %i[edit update destroy]

  def reorder
    authorize(NavbarItem)
    navbar_item = NavbarItem.find(params[:id])
    navbar_item.insert_at(params[:position].to_i)
    head :ok
  end

  def index
    authorize(NavbarItem)
    @navbar_items = NavbarItem.ordered
  end

  def new
    @navbar_item = NavbarItem.new
    authorize(@navbar_item)
  end

  def edit
  end

  def create
    @navbar_item = NavbarItem.new(navbar_item_params)
    authorize(@navbar_item)

    if @navbar_item.save
      redirect_to admin_navbar_items_path, notice: t(".notice")
    else
      flash.now[:alert] = @navbar_item.errors.full_messages.to_sentence
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @navbar_item.update(navbar_item_params)
      redirect_to admin_navbar_items_path, notice: t(".notice")
    else
      flash.now[:alert] = @navbar_item.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @navbar_item.destroy!
    redirect_to admin_navbar_items_path, notice: t(".notice")
  end

  private

  def set_navbar_item
    @navbar_item = NavbarItem.find(params[:id])
    authorize(@navbar_item)
  end

  def navbar_item_params
    params.require(:navbar_item).permit(:icon, :title, :path)
  end
end
