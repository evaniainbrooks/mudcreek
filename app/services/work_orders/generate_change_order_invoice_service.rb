module WorkOrders
  class GenerateChangeOrderInvoiceService
    Result = Data.define(:invoice, :error) do
      def success? = error.nil?
    end

    def self.call(change_order:)
      return Result.new(invoice: nil, error: "Invoice already generated") if change_order.invoice.present?

      invoice = nil

      ActiveRecord::Base.transaction do
        work_order = change_order.work_order
        location   = work_order.location

        line_item = TaxCalculator::LineItem.new(
          amount_cents: change_order.amount_cents,
          tax_exempt:   change_order.tax_exempt
        )

        tax_cents = TaxCalculator.new([ line_item ], location.tax_rate).tax_cents

        invoice = Invoice.create!(
          user:         work_order.user,
          change_order: change_order,
          total_cents:  change_order.amount_cents + tax_cents
        )

        invoice.invoice_items.create!(
          name:         change_order.number,
          amount_cents: change_order.amount_cents
        )

        if tax_cents > 0
          invoice.invoice_items.create!(
            name:         "Tax (#{location.tax_rate_percent}%)",
            amount_cents: tax_cents
          )
        end
      end

      Result.new(invoice:, error: nil)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(invoice: nil, error: e.message)
    end
  end
end
