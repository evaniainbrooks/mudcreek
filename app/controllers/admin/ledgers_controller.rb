class Admin::LedgersController < Admin::BaseController
  before_action :set_ledger, only: %i[show edit update destroy]

  def index
    authorize(Ledger)
    @pagy, @ledgers = pagy(:keyset, Ledger.includes(:location).ordered)
  end

  def show
    @entries        = @ledger.entries.ordered.includes(:user, receipt_attachment: :blob).load
    @total_credits  = @ledger.entries.credits.sum(:amount) || 0
    @total_debits   = @ledger.entries.debits.sum(:amount) || 0
    @balance        = @total_credits - @total_debits
    @total_subtotal = @entries.sum { |e| e.credit? ? e.subtotal.to_d : -e.subtotal.to_d }
    @total_tax      = @entries.sum { |e| e.tax_amount.to_d }
    @entry          = Ledger::Entry.new(entry_type: "credit", recorded_at: Time.current)
  end

  def new
    @ledger = Ledger.new
    authorize(@ledger)
    @locations = Location.ordered
  end

  def edit
    @locations = Location.ordered
  end

  def create
    @ledger = Ledger.new(ledger_params)
    authorize(@ledger)

    if @ledger.save
      redirect_to admin_ledger_path(@ledger), notice: "Ledger was successfully created."
    else
      @locations = Location.ordered
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @ledger.update(ledger_params)
      redirect_to admin_ledger_path(@ledger), notice: "Ledger was successfully updated."
    else
      @locations = Location.ordered
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @ledger.destroy!
    redirect_to admin_ledgers_path, notice: "Ledger was successfully deleted."
  end

  private

  def set_ledger
    @ledger = Ledger.includes(:location).find_by!(hashid: params[:hashid])
    authorize(@ledger)
  end

  def ledger_params
    params.require(:ledger).permit(:name, :description, :location_id)
  end
end
