module Admin
  class TenantsController < Admin::BaseController
    def show
      @tenant = Current.tenant
      authorize(@tenant)
    end

    def update
      @tenant = Current.tenant
      authorize(@tenant)

      @tenant.logo.purge_later if params[:remove_logo]
      if @tenant.update(tenant_params)
        redirect_to admin_tenant_path, notice: "Tenant was successfully updated."
      else
        render :show, status: :unprocessable_content
      end
    end

    private

    def tenant_params
      params.require(:tenant).permit(
        :name,
        :logo,
        :description,
        :currency,
        address_attributes: %i[id street_address city province postal_code country _destroy]
      )
    end
  end
end
