class Admin::DeliveryMethodsController < Admin::BaseController
  before_action :set_delivery_method, only: [:update, :destroy]

  def index
    authorize(DeliveryMethod)
    @delivery_method = DeliveryMethod.new
    @delivery_methods = DeliveryMethod.order(:name)
  end

  def create
    @delivery_method = DeliveryMethod.new(delivery_method_params)
    authorize(@delivery_method)
    if @delivery_method.save
      redirect_to admin_delivery_methods_path, notice: "\"#{@delivery_method.name}\" was successfully created."
    else
      @delivery_methods = DeliveryMethod.order(:name)
      render :index, status: :unprocessable_entity
    end
  end

  def update
    @delivery_method.update(delivery_method_params)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to admin_delivery_methods_path }
    end
  end

  def destroy
    @delivery_method.destroy!
    redirect_to admin_delivery_methods_path, notice: "\"#{@delivery_method.name}\" was successfully deleted."
  end

  private

  def set_delivery_method
    @delivery_method = DeliveryMethod.find(params[:id])
    authorize(@delivery_method)
  end

  def delivery_method_params
    params.require(:delivery_method).permit(:name, :price, :active, :address_required)
  end
end
