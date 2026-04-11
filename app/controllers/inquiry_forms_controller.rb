class InquiryFormsController < ApplicationController
  allow_unauthenticated_access only: [ :show ]

  def show
    @inquiry_form = InquiryForm.published.find_by!(slug: params[:slug])
    @inquiry = Inquiry.new
  end
end
