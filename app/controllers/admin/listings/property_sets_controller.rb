class Admin::Listings::PropertySetsController < Admin::BaseController
  def index
    authorize(Listings::PropertySet)
    @property_set = Listings::PropertySet.new
    @property_sets = Current.tenant.property_sets.order(:name)
  end

  def show
    @property_set = Current.tenant.property_sets.find(params[:id])
    authorize(@property_set)
    @properties = @property_set.properties.order(:position)
    @property = @property_set.properties.build
  end

  def update
    @property_set = Current.tenant.property_sets.find(params[:id])
    authorize(@property_set)
    @property_set.update(property_set_params)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to admin_listings_property_sets_path }
    end
  end

  def destroy
    @property_set = Current.tenant.property_sets.find(params[:id])
    authorize(@property_set)
    @property_set.destroy!
    redirect_to admin_listings_property_sets_path, notice: "\"#{@property_set.name}\" was successfully deleted."
  end

  def reorder
    authorize(Listings::PropertySet)
    property = Listings::Property.find(params[:id])
    property.insert_at(params[:position].to_i)
    head :ok
  end

  def create
    @property_set = Listings::PropertySet.new(property_set_params)
    authorize(@property_set)
    if @property_set.save
      redirect_to admin_listings_property_sets_path, notice: "\"#{@property_set.name}\" was successfully created."
    else
      @property_sets = Current.tenant.property_sets.order(:name)
      render :index, status: :unprocessable_content
    end
  end

  private

  def property_set_params
    params.require(:listings_property_set).permit(:name)
  end
end
