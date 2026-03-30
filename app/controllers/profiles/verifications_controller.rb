class Profiles::VerificationsController < Profiles::BaseController
  def show
    @verification = Current.user.verification || Current.user.build_verification
  end

  def update
    @verification = Current.user.verification || Users::Verification.new(user: Current.user)

    if @verification.update(verification_params)
      redirect_to profile_verification_path, notice: "Verification document uploaded."
    else
      render :show, status: :unprocessable_content
    end
  end

  private

  def verification_params
    params.permit(verification: [ :verification_document ]).fetch(:verification, {})
  end
end
