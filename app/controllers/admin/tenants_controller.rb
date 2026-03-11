module Admin
  class TenantsController < Admin::BaseController
    def show
      @tenant = Current.tenant
      authorize(@tenant)
      @tenant.build_default_bid_increment_schedule if @tenant.default_bid_increment_schedule.nil?
      @tenant.default_bid_increment_schedule.tiers.build if @tenant.default_bid_increment_schedule.tiers.none?
    end

    ATTACHMENTS = %i[logo listing_placeholder auction_placeholder default_terms_and_conditions].freeze

    def update
      @tenant = Current.tenant
      authorize(@tenant)

      ATTACHMENTS.each do |name|
        if params[:"remove_#{name}"]
          @tenant.public_send(name).purge_later
        else
          file = params.dig(:tenant, name)
          if file.is_a?(ActionDispatch::Http::UploadedFile) && file.original_filename.present?
            @tenant.public_send(name).attach(file)
          end
        end
      end

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
        :email_address,
        :phone_number,
        :timezone,
        :tagline,
        :description,
        :currency,
        :custom_domain,
        address_attributes: %i[id street_address city province postal_code country _destroy],
        social_media_accounts_attributes: %i[id platform slug icon position _destroy],
        default_bid_increment_schedule_attributes: [
          :id,
          { tiers_attributes: [:id, :min_amount_cents, :increment_cents, :_destroy] }
        ]
      )
    end
  end
end
