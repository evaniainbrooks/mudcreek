class Admin::Users::DisablementsController < Admin::BaseController
  before_action :set_user

  def create
    authorize(@user, :update?)
    original_email = @user.email_address
    host = Rails.application.config.action_mailer.default_url_options[:host]
    @user.update!(
      disabled_email_address: original_email,
      disabled_at: Time.current,
      email_address: "disabled#{SecureRandom.hex(8)}@#{host}"
    )
    @user.sessions.destroy_all
    redirect_to admin_users_path, notice: t(".notice", email: original_email)
  end

  def destroy
    authorize(@user, :update?)
    original_email = @user.disabled_email_address
    if @user.update(email_address: original_email, disabled_email_address: nil, disabled_at: nil)
      redirect_to admin_users_path, notice: t(".notice", email: @user.email_address)
    else
      redirect_to admin_users_path, alert: t(".alert", errors: @user.errors.full_messages.to_sentence)
    end
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end
end
