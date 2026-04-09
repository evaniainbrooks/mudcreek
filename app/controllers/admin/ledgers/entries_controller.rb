class Admin::Ledgers::EntriesController < Admin::BaseController
  before_action :set_ledger

  def create
    @entry = @ledger.entries.new(entry_params.merge(user: Current.user))
    authorize(@entry)

    @entries       = @ledger.entries.ordered.includes(:user)
    @total_credits = @ledger.entries.credits.sum(:amount) || 0
    @total_debits  = @ledger.entries.debits.sum(:amount) || 0
    @balance       = @total_credits - @total_debits

    if @entry.save
      @new_entry = Ledger::Entry.new(entry_type: @entry.entry_type, recorded_at: Time.current)
    else
      @new_entry = @entry
      render :create, status: :unprocessable_content
    end
  end

  def destroy
    @entry = @ledger.entries.find(params[:id])
    authorize(@entry)
    @entry.destroy!

    @entries       = @ledger.entries.ordered.includes(:user)
    @total_credits = @ledger.entries.credits.sum(:amount) || 0
    @total_debits  = @ledger.entries.debits.sum(:amount) || 0
    @balance       = @total_credits - @total_debits
    @new_entry     = Ledger::Entry.new(entry_type: "credit", recorded_at: Time.current)
  end

  private

  def set_ledger
    @ledger = Ledger.find_by!(hashid: params[:ledger_hashid])
  end

  def entry_params
    params.require(:ledger_entry).permit(:description, :entry_type, :amount, :memo, :recorded_at)
  end
end
