module Admin
  class EmailAliasesController < Admin::BaseController
    def index
      authorize(EmailAlias, policy_class: EmailAliasPolicy)
      @root_domain = PublicSuffix.domain(Current.tenant.custom_domain) if Current.tenant.custom_domain.present?
      @improvmx_domain = ::Improvmx::Domain.find_by(tenant: Current.tenant)
      @aliases = EmailAlias.order(:alias)
    end

    def create
      authorize(EmailAlias, :create?, policy_class: EmailAliasPolicy)
      CreateEmailAliasJob.perform_later(Current.tenant.id, params[:email_alias][:alias], params[:email_alias][:forward])
      redirect_to admin_email_aliases_path, notice: t(".notice")
    end

    def destroy
      @alias = EmailAlias.find(params[:id])
      authorize(@alias)
      DeleteEmailAliasJob.perform_later(@alias.id)
      redirect_to admin_email_aliases_path, notice: t(".notice")
    end
  end
end
