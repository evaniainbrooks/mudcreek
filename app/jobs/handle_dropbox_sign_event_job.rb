class HandleDropboxSignEventJob < ApplicationJob
  queue_as :default

  def perform(event)
    request_id = event.dig("signature_request", "signature_request_id")
    return unless request_id.present?

    work_order = WorkOrder.unscoped.find_by(dropbox_sign_request_id: request_id)
    if work_order.present?
      Current.tenant = work_order.tenant
      ProcessWorkOrderContractJob.perform_later(work_order.id)
      return
    end

    change_order = ChangeOrder.unscoped.find_by(dropbox_sign_request_id: request_id)
    return unless change_order.present?

    Current.tenant = change_order.work_order.tenant
    ProcessSignedChangeOrderJob.perform_later(change_order.id)
  end
end
