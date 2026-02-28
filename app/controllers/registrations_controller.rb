class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: :create
  rate_limit to: 5, within: 1.minute, only: :create, with: -> { redirect_to new_session_path, alert: "Too many registration attempts. Try again later." }

  def create
    user = User.new(registration_params)
    if user.save
      RegistrationsMailer.activate(user).deliver_later
      redirect_to new_session_path, notice: "Check your email for an activation link."
    else
      redirect_to new_session_path, alert: user.errors.full_messages.to_sentence
    end
  end

  private

  def registration_params
    params.expect(user: [ :first_name, :last_name, :email_address, :password, :password_confirmation ])
  end
end
