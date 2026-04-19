class Admin::Ledgers::EntriesController < Admin::BaseController
  before_action :set_ledger

  def create
    @entry = @ledger.entries.new(entry_params.merge(user: Current.user))
    authorize(@entry)

    if @entry.save
      load_aggregates
      @new_entry = Ledger::Entry.new(entry_type: @entry.entry_type, recorded_at: Time.current)
    else
      load_aggregates
      @new_entry = @entry
      render :create, status: :unprocessable_content
    end
  end

  def destroy
    @entry = @ledger.entries.find(params[:id])
    authorize(@entry)
    @entry.destroy!

    load_aggregates
    @new_entry = Ledger::Entry.new(entry_type: "credit", recorded_at: Time.current)
  end

  private

  def load_aggregates
    @entries           = @ledger.entries.ordered.includes(:user, receipt_attachment: :blob).load
    @total_credits     = @ledger.entries.credits.sum(:amount) || 0
    @total_debits      = @ledger.entries.debits.sum(:amount) || 0
    @balance           = @total_credits - @total_debits
    @total_tax_credits = @entries.select(&:credit?).sum { |e| e.tax_amount.to_d }
    @total_tax_debits  = @entries.select(&:debit?).sum { |e| e.tax_amount.to_d }
    @tax_balance       = @total_tax_credits - @total_tax_debits
    @total_subtotal    = @balance - @tax_balance
  end

  def set_ledger
    @ledger = Ledger.includes(:location).find_by!(hashid: params[:ledger_hashid])
  end

  def entry_params
    params.require(:ledger_entry).permit(:description, :entry_type, :amount, :memo, :recorded_at, :receipt, :taxed)
  end
end
