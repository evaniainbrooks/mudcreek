module Admin
  class TenantsController < Admin::BaseController
    def show
      @tenant = Current.tenant
      authorize(@tenant)
      @tenant.build_default_bid_increment_schedule if @tenant.default_bid_increment_schedule.nil?
      @tenant.default_bid_increment_schedule.tiers.build if @tenant.default_bid_increment_schedule.tiers.none?
    end

    def update
      @tenant = Current.tenant
      authorize(@tenant)

      @tenant.logo.purge_later if params[:remove_logo]
      @tenant.default_terms_and_conditions.purge_later if params[:remove_default_terms_and_conditions]
      if @tenant.update(tenant_params)
        redirect_to admin_tenant_path, notice: "Tenant was successfully updated."
      else
        render :show, status: :unprocessable_content
      end
    end

    private

    def tenant_params
      p = params.require(:tenant).permit(
        :name,
        :email_address,
        :logo,
        :default_terms_and_conditions,
        :description,
        :currency,
        :custom_domain,
        address_attributes: %i[id street_address city province postal_code country _destroy],
        default_bid_increment_schedule_attributes: [
          :id,
          { tiers_attributes: [:id, :min_amount_cents, :increment_cents, :_destroy] }
        ]
      )
      p.delete(:logo) if p[:logo].blank?
      p.delete(:default_terms_and_conditions) if p[:default_terms_and_conditions].blank?
      p
    end
  end
end
