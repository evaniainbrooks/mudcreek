class LedgersController < ApplicationController
  allow_unauthenticated_access
  layout "checkin"

  def show
    @ledger = Ledger.includes(:location).find_by!(hashid: params[:hashid])
    @entry  = Ledger::Entry.new(entry_type: "credit")
  end
end
