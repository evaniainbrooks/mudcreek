class Ledgers::EntriesController < ApplicationController
  allow_unauthenticated_access
  layout "checkin"

  before_action :set_ledger

  def create
    @entry = @ledger.entries.new(entry_params.merge(user: Current.user))

    if @entry.save
      redirect_to ledger_path(@ledger), notice: "Entry added."
    else
      @entry.entry_type ||= "credit"
      render template: "ledgers/show", status: :unprocessable_content
    end
  end

  private

  def set_ledger
    @ledger = Ledger.includes(:location).find_by!(hashid: params[:ledger_hashid])
    raise ActiveRecord::RecordNotFound unless @ledger.shared?
  end

  def entry_params
    params.require(:ledger_entry).permit(:description, :entry_type, :amount, :taxed)
  end
end
