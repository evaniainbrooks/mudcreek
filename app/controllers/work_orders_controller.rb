class WorkOrdersController < ApplicationController
  allow_unauthenticated_access only: [:signed]

  def signed
    @work_order = WorkOrder.find_by!(number: params[:number])
  end
end
