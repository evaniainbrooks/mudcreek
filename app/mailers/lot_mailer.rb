class LotMailer < ApplicationMailer
  def settlement_updated(settlement)
    @settlement = settlement
    @lot        = settlement.lot
    @owner      = @lot.owner
    @line_items = settlement.settlement_line_items.order(:created_at)

    mail(to: @owner.email_address, subject: "Consignment credit update \u2014 #{@lot.name}")
  end
end
