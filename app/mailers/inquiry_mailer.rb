class InquiryMailer < ApplicationMailer
  def inquiry_received(inquiry)
    @inquiry      = inquiry
    @inquiry_form = inquiry.inquiry_form

    mail(
      to:      @inquiry_form.notification_recipient.email_address,
      subject: "New inquiry via #{@inquiry_form.name}"
    )
  end

  def inquiry_confirmation(inquiry)
    @inquiry      = inquiry
    @inquiry_form = inquiry.inquiry_form

    mail(
      to:      inquiry.email,
      subject: "We received your inquiry"
    )
  end
end
