class Admin::InquiriesController < Admin::BaseController
  before_action :set_inquiry, only: [ :show ]

  def index
    authorize(Inquiry)
    @filter_total = Inquiry.count
    @q = Inquiry.ransack(params[:q])
    scope = @q.result.includes(:inquiry_form, :user).order(created_at: :desc, id: :desc)
    @filter_count = scope.count
    @pagy, @inquiries = pagy(:keyset, scope)

    respond_to do |format|
      format.html
      format.turbo_stream do
        if params[:page].present?
          render turbo_stream: [
            turbo_stream.append("admin-inquiries-tbody", partial: "admin/inquiries/inquiry_row", collection: @inquiries, as: :inquiry),
            turbo_stream.replace("sentinel", partial: "admin/inquiries/sentinel", locals: { pagy: @pagy, q: params[:q] })
          ]
        else
          render :index, formats: [ :html ]
        end
      end
    end
  end

  def show
  end

  private

  def set_inquiry
    @inquiry = Inquiry.includes(:inquiry_form, :user).find(params[:id])
    authorize(@inquiry)
  end
end
