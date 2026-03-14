class Admin::Listings::DeliveryMethodSets::DeliveryMethodsController < Admin::BaseController
  before_action :set_delivery_method_set

  def create
    delivery_method = DeliveryMethod.find(params[:delivery_method_id])
    @delivery = @delivery_method_set.deliveries.build(delivery_method: delivery_method)
    authorize(@delivery)
    if @delivery.save
      redirect_to admin_listings_delivery_method_set_path(@delivery_method_set), notice: "\"#{delivery_method.name}\" was added."
    else
      @deliveries = @delivery_method_set.deliveries.includes(:delivery_method).order("delivery_methods.name")
      @available_methods = DeliveryMethod.where.not(id: @delivery_method_set.delivery_method_ids).order(:name)
      render "admin/listings/delivery_method_sets/show", status: :unprocessable_content
    end
  end

  def destroy
    @delivery = @delivery_method_set.deliveries.find(params[:id])
    authorize(@delivery)
    @delivery.destroy!
    redirect_to admin_listings_delivery_method_set_path(@delivery_method_set), notice: "\"#{@delivery.delivery_method.name}\" was removed."
  end

  private

  def set_delivery_method_set
    @delivery_method_set = Current.tenant.delivery_method_sets.find(params[:delivery_method_set_id])
  end
end
