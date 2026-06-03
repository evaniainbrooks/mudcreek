module Admin
  class TenantsController < Admin::BaseController
    def show
      @tenant = Current.tenant
      authorize(@tenant)
      @delivery_method_sets = @tenant.delivery_method_sets.order(:name)
      @pages = Page.published.top_level.order(:position, :title)
      @tenant.build_default_bid_increment_schedule if @tenant.default_bid_increment_schedule.nil?
      @tenant.default_bid_increment_schedule.tiers.build if @tenant.default_bid_increment_schedule.tiers.none?
    end

    ATTACHMENTS = %i[logo favicon listing_placeholder auction_placeholder default_terms_and_conditions].freeze

    def update
      @tenant = Current.tenant
      authorize(@tenant)

      ATTACHMENTS.each do |name|
        if params[:"remove_#{name}"]
          @tenant.public_send(name).purge_later
        else
          file = params.dig(:tenant, name)
          case file
          when ActionDispatch::Http::UploadedFile
            @tenant.public_send(name).attach(file) if file.original_filename.present?
          when String
            @tenant.public_send(name).attach(file) if file.present?
          end
        end
      end

      if @tenant.update(tenant_params)
        redirect_to admin_tenant_path, notice: t(".notice")
      else
        @delivery_method_sets = @tenant.delivery_method_sets.order(:name)
        @pages = Page.published.top_level.order(:position, :title)
        flash.now[:alert] = @tenant.errors.full_messages.to_sentence
        render :show, status: :unprocessable_content
      end
    end

    private

    def tenant_params
      params.require(:tenant).permit(
        :name,
        :homepage_page_id,
        :default_delivery_method_set_id,
        :email_address,
        :phone_number,
        :timezone,
        :tagline,
        :description,
        :notice,
        :currency,
        :website,
        :custom_domain,
        :square_location_id,
        :ga4_measurement_id,
        :facebook_pixel_id,
        :facebook_domain_verification,
        :google_site_verification,
        :primary_color,
        :secondary_color,
        :tertiary_color,
        :background_color,
        :text_color,
        :link_color,
        :footer_color,
        :card_color,
        :container_color,
        features_attributes: Tenant::Features.attribute_names.map(&:to_sym),
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
