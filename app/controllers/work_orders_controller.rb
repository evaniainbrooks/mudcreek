class WorkOrdersController < ApplicationController
  allow_unauthenticated_access only: [ :signed, :portal ]

  def signed
    @work_order = WorkOrder.find_by!(number: params[:number])
  end

  def portal
    @work_order = WorkOrder
      .includes(:work_order_items, :work_order_milestones, :change_orders, :address)
      .find_by!(number: params[:number])
    raise ActiveRecord::RecordNotFound unless params[:token] == @work_order.client_upload_token

    if request.post?
      @work_order.client_attachments.attach(params[:files]) if params[:files].present?
      return redirect_to portal_work_order_path(@work_order, token: params[:token]),
                         notice: "Files uploaded successfully."
    end

    @portal_steps = [
      { state: "estimate_sent", label: "Estimate Sent", ts: @work_order.estimate_sent_at },
      { state: "contracted",    label: "Contracted",    ts: @work_order.contracted_at    },
      { state: "in_progress",   label: "In Progress",   ts: nil                          },
      { state: "completed",     label: "Completed",     ts: @work_order.completed_at     }
    ]
  end
end
