class QrCodePolicy < ApplicationPolicy
  def qr_image?
    show?
  end
end
