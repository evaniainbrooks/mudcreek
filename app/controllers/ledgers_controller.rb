class LedgersController < ApplicationController
  allow_unauthenticated_access
  layout "checkin"

  def show
    @ledger = Ledger.includes(:location).find_by!(hashid: params[:hashid])
    raise ActiveRecord::RecordNotFound unless @ledger.shared?
    @entry  = Ledger::Entry.new(entry_type: "debit")
  end
end
