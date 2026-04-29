class SyncSquareTransactionsJob < ApplicationJob
  queue_as :default

  def perform(lookback_hours: 1)
    begin_time = lookback_hours.hours.ago.iso8601
    end_time   = Time.current.iso8601
    cursor     = nil

    Tenant.find_each do |tenant|
      Current.tenant = tenant

      loop do
        response = SquareClient.client.payments.list(
          location_id: SquareClient.location_id,
          begin_time:,
          end_time:,
          cursor:
        )

        (response.data.payments || []).each do |payment|
          next unless payment["status"] == "COMPLETED"
          next if payment["reference_id"].present?

          SyncSquarePosPaymentService.call(payment_data: payment, tenant: tenant)
        end

        cursor = response.data.cursor
        break if cursor.nil?
      end
    end
  ensure
    Current.tenant = nil
  end
end
