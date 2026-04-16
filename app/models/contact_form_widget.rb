class ContactFormWidget < Widget
  belongs_to :inquiry_form

  validates :inquiry_form_id, presence: true
end
