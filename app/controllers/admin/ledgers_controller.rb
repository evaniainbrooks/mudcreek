class Admin::LedgersController < Admin::BaseController
  before_action :set_ledger, only: %i[show edit update destroy]

  def index
    authorize(Ledger)
    @pagy, @ledgers = pagy(:keyset, Ledger.ordered)
  end

  def show
    @entries       = @ledger.entries.ordered.includes(:user)
    @total_credits = @ledger.entries.credits.sum(:amount) || 0
    @total_debits  = @ledger.entries.debits.sum(:amount) || 0
    @balance       = @total_credits - @total_debits
    @entry         = Ledger::Entry.new(entry_type: "credit", recorded_at: Time.current)
  end

  def new
    @ledger = Ledger.new
    authorize(@ledger)
  end

  def edit; end

  def create
    @ledger = Ledger.new(ledger_params)
    authorize(@ledger)

    if @ledger.save
      redirect_to admin_ledger_path(@ledger), notice: "Ledger was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @ledger.update(ledger_params)
      redirect_to admin_ledger_path(@ledger), notice: "Ledger was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @ledger.destroy!
    redirect_to admin_ledgers_path, notice: "Ledger was successfully deleted."
  end

  private

  def set_ledger
    @ledger = Ledger.find_by!(hashid: params[:hashid])
    authorize(@ledger)
  end

  def ledger_params
    params.require(:ledger).permit(:name, :description)
  end
end
