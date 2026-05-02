class Ledgers::EntriesController < ApplicationController
  allow_unauthenticated_access
  layout "checkin"

  before_action :set_ledger
  before_action :set_entry, only: [:destroy]

  def create
    @entry = @ledger.entries.new(entry_params.merge(user: Current.user))

    if @entry.save
      type   = @entry.entry_type.capitalize
      amount = view_context.number_to_currency(@entry.amount)
      undo   = view_context.link_to("Undo", ledger_entry_path(@ledger, @entry), data: { turbo_method: :delete }, class: "alert-link")
      redirect_to ledger_path(@ledger), notice: "A #{type} of #{amount} for #{@entry.description} was added. #{undo}"
    else
      @entry.entry_type ||= "debit"
      render template: "ledgers/show", status: :unprocessable_content
    end
  end

  def destroy
    @entry.destroy!
    redirect_to ledger_path(@ledger), notice: "Entry removed."
  end

  private

  def set_ledger
    @ledger = Ledger.includes(:location).find_by!(hashid: params[:ledger_hashid])
    raise ActiveRecord::RecordNotFound unless @ledger.shared?
  end

  def set_entry
    @entry = @ledger.entries.find_by!(id: params[:id], user: Current.user)
  end

  def entry_params
    params.require(:ledger_entry).permit(:description, :entry_type, :amount, :taxed, :receipt)
  end
end
