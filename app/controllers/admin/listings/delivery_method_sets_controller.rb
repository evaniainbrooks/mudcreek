class Admin::Listings::DeliveryMethodSetsController < Admin::BaseController
  def index
    authorize(Listings::DeliveryMethodSet)
    @delivery_method_set = Listings::DeliveryMethodSet.new
    @delivery_method_sets = Current.tenant.delivery_method_sets.order(:name)
  end

  def show
    @delivery_method_set = Current.tenant.delivery_method_sets.find(params[:id])
    authorize(@delivery_method_set)
    @deliveries = @delivery_method_set.deliveries.includes(:delivery_method).order("delivery_methods.name")
    @available_methods = DeliveryMethod.where.not(id: @delivery_method_set.delivery_method_ids).order(:name)
  end

  def create
    @delivery_method_set = Listings::DeliveryMethodSet.new(delivery_method_set_params)
    authorize(@delivery_method_set)
    if @delivery_method_set.save
      redirect_to admin_listings_delivery_method_sets_path, notice: t(".notice", name: @delivery_method_set.name)
    else
      @delivery_method_sets = Current.tenant.delivery_method_sets.order(:name)
      render :index, status: :unprocessable_content
    end
  end

  def update
    @delivery_method_set = Current.tenant.delivery_method_sets.find(params[:id])
    authorize(@delivery_method_set)
    @delivery_method_set.update(delivery_method_set_params)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to admin_listings_delivery_method_sets_path }
    end
  end

  def destroy
    @delivery_method_set = Current.tenant.delivery_method_sets.find(params[:id])
    authorize(@delivery_method_set)
    @delivery_method_set.destroy!
    redirect_to admin_listings_delivery_method_sets_path, notice: t(".notice", name: @delivery_method_set.name)
  end

  private

  def delivery_method_set_params
    params.require(:listings_delivery_method_set).permit(:name)
  end
end
