class Admin::InvoicesController < Admin::BaseController
  before_action :set_invoice, only: [ :show ]

  def index
    authorize(Invoice)
    @q = Invoice.ransack(params[:q])
    scope = @q.result.includes(:user, :auction).order(created_at: :desc, id: :desc)
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

  private

  def set_invoice
    @invoice = Invoice.includes(:user, :auction, :offer, invoice_items: :listing).find_by!(number: params[:number])
    authorize(@invoice)
  end
end
