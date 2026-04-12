require "rails_helper"

RSpec.describe QrScan, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "associations" do
    it "belongs to a qr_code" do
      qr_code = create(:qr_code)
      scan = QrScan.create!(qr_code: qr_code)
      expect(scan.qr_code).to eq(qr_code)
    end
  end
end
