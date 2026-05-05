class Admin::Listings::PropertySets::PropertiesController < Admin::BaseController
  before_action :set_property_set

  def create
    @property = @property_set.properties.build(property_params)
    authorize(@property)
    if @property.save
      redirect_to admin_listings_property_set_path(@property_set), notice: t(".notice", name: @property.name)
    else
      @properties = @property_set.properties.order(:position)
      render "admin/listings/property_sets/show", status: :unprocessable_content
    end
  end

  def update
    @property = @property_set.properties.find(params[:id])
    authorize(@property)
    @property.update(property_params)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to admin_listings_property_set_path(@property_set) }
    end
  end

  def destroy
    property = @property_set.properties.find(params[:id])
    authorize(property)
    property.destroy!
    redirect_to admin_listings_property_set_path(@property_set), notice: t(".notice", name: property.name)
  end

  private

  def property_params
    params.require(:listings_property).permit(:name, :value, :icon)
  end

  def set_property_set
    @property_set = Current.tenant.property_sets.find(params[:property_set_id])
  end
end
