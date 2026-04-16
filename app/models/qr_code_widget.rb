class QrCodeWidget < Widget
  belongs_to :qr_code

  validates :qr_code_id, presence: true
end
