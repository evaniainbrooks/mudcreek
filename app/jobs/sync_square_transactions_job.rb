class SyncSquareTransactionsJob < ApplicationJob
  queue_as :default

  def perform(lookback_hours: 1)
    begin_time = lookback_hours.hours.ago.iso8601
    end_time   = Time.current.iso8601

    Tenant.find_each do |tenant|
      Current.tenant = tenant

      next unless tenant.features.sync_square_pos_payments?

      location_id = tenant.square_location_id.presence || SquareClient.location_id

      SquareClient.client.payments.list(
        location_id:,
        begin_time:,
        end_time:
      ).each do |payment|
        next unless payment.status == "COMPLETED"
        next if payment.reference_id.present?

        SyncSquarePosPaymentService.call(payment_data: payment.to_h, tenant: tenant)
      end
    end
  ensure
    Current.tenant = nil
  end
end
