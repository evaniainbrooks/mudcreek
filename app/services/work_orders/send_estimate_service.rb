module WorkOrders
  class SendEstimateService
    Result = Data.define(:work_order, :error) do
      def success? = error.nil?
    end

    def self.call(work_order:)
      html = ApplicationController.renderer.render(
        template: "work_orders/estimate",
        assigns: { work_order: },
        layout: false
      )

      pdf_bytes = Grover.new(html, format: "A4", print_background: true).to_pdf

      work_order.estimate_pdf.attach(
        io: StringIO.new(pdf_bytes),
        filename: "estimate-#{work_order.number}.pdf",
        content_type: "application/pdf"
      )

      work_order.update!(
        state:            :estimate_sent,
        estimate_sent_at: Time.current
      )

      WorkOrderMailer.estimate_email(work_order).deliver_later

      Result.new(work_order:, error: nil)
    rescue ActiveRecord::RecordInvalid, Grover::JavaScript::Error => e
      Result.new(work_order: nil, error: e.message)
    end
  end
end
