class ActivationsController < ApplicationController
  allow_unauthenticated_access only: :show

  def show
    user = User.find_by_token_for!(:activation, params[:token])
    user.update!(activated_at: Time.current)
    start_new_session_for user
    redirect_to after_authentication_url, notice: "Your account has been activated."
  rescue ActiveRecord::RecordNotFound, ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to new_session_path, alert: "Activation link is invalid or has expired."
  end
end
