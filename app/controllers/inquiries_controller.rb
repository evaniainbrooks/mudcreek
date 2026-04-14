class InquiriesController < ApplicationController
  allow_unauthenticated_access only: [ :create ]

  before_action :set_inquiry_form

  def create
    @inquiry = @inquiry_form.inquiries.new(inquiry_params)
    @inquiry.user = Current.user

    if @inquiry.save
      InquiryMailer.inquiry_received(@inquiry).deliver_later
      InquiryMailer.inquiry_confirmation(@inquiry).deliver_later
      redirect_to @inquiry_form.redirect_path, notice: "Your inquiry has been submitted. We'll be in touch soon."
    else
      render "inquiry_forms/show", status: :unprocessable_content
    end
  end

  private

  def set_inquiry_form
    @inquiry_form = InquiryForm.published.find_by!(slug: params[:form_slug])
  end

  def inquiry_params
    params.require(:inquiry).permit(:name, :email, :phone, :message)
  end
end
