class Admin::DiscountCodesController < Admin::BaseController
  before_action :set_discount_code, only: [:destroy]

  def index
    authorize(DiscountCode)
    @discount_code = DiscountCode.new
    @discount_codes = DiscountCode.order(:key)
  end

  def create
    @discount_code = DiscountCode.new(discount_code_params)
    authorize(@discount_code)
    if @discount_code.save
      redirect_to admin_discount_codes_path, notice: "Discount code \"#{@discount_code.key}\" was successfully created."
    else
      @discount_codes = DiscountCode.order(:key)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @discount_code.destroy!
    redirect_to admin_discount_codes_path, notice: "Discount code \"#{@discount_code.key}\" was successfully deleted."
  end

  private

  def set_discount_code
    @discount_code = DiscountCode.find(params[:id])
    authorize(@discount_code)
  end

  def discount_code_params
    params.require(:discount_code).permit(:key, :discount_type, :amount, :start_at, :end_at)
  end
end
