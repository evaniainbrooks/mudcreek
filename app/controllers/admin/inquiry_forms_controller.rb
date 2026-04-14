class Admin::InquiryFormsController < Admin::BaseController
  before_action :set_inquiry_form, only: %i[show edit update destroy]

  def index
    authorize(InquiryForm)
    @inquiry_forms = InquiryForm.includes(:notification_recipient).order(:name)
  end

  def show
  end

  def new
    @inquiry_form = InquiryForm.new
    authorize(@inquiry_form)
  end

  def edit
  end

  def create
    @inquiry_form = InquiryForm.new(inquiry_form_params)
    authorize(@inquiry_form)

    if @inquiry_form.save
      redirect_to admin_inquiry_forms_path, notice: "Inquiry form was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @inquiry_form.update(inquiry_form_params)
      redirect_to admin_inquiry_forms_path, notice: "Inquiry form was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @inquiry_form.destroy!
    redirect_to admin_inquiry_forms_path, notice: "Inquiry form was successfully deleted."
  end

  private

  def set_inquiry_form
    @inquiry_form = InquiryForm.find_by!(slug: params[:id])
    authorize(@inquiry_form)
  end

  def inquiry_form_params
    params.require(:inquiry_form).permit(:name, :slug, :description, :cta_label, :redirect_path, :notification_recipient_id, :published)
  end
end
