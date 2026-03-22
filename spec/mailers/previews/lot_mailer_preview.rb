class LotMailerPreview < ActionMailer::Preview
  def payout_sent
    Current.tenant = Tenant.find_by(default: true) || Tenant.first!
    lot = Lot.joins(:settlement).first!
    LotMailer.payout_sent(lot)
  end

  def settlement_updated
    Current.tenant = Tenant.find_by(default: true) || Tenant.first!
    settlement = Settlement.includes(:settlement_line_items, lot: :owner).first!
    LotMailer.settlement_updated(settlement)
  end
end
