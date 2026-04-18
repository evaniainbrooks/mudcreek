class Admin::InvoicesController < Admin::BaseController
  before_action :set_invoice, only: [ :show, :update ]

  def index
    authorize(Invoice)
    @filter_total = Invoice.count
    @q = Invoice.ransack(params[:q])
    scope = @q.result.includes(:user, :auction).order(created_at: :desc, id: :desc)
    @filter_count = scope.count
    @pagy, @invoices = pagy(:keyset, scope)

    respond_to do |format|
      format.html
      format.turbo_stream do
        if params[:page].present?
          render turbo_stream: [
            turbo_stream.append("admin-invoices-tbody", partial: "admin/invoices/invoice_row", collection: @invoices, as: :invoice),
            turbo_stream.replace("sentinel", partial: "admin/invoices/sentinel", locals: { pagy: @pagy, q: params[:q] })
          ]
        else
          render :index, formats: [:html]
        end
      end
    end
  end

  def show
  end

  def update
    attrs = invoice_params
    @invoice.receipt.purge if attrs.delete(:remove_receipt) == "1"

    if @invoice.update(attrs)
      redirect_to admin_invoice_path(@invoice), notice: "Invoice updated."
    else
      render :show, status: :unprocessable_content
    end
  end

  private

  def set_invoice
    @invoice = Invoice.includes(:user, :auction, :offer, invoice_items: :listing).find_by!(number: params[:number])
    authorize(@invoice)
  end

  def invoice_params
    params.expect(invoice: [ :status, :admin_notes, :receipt, :remove_receipt ])
  end
end
