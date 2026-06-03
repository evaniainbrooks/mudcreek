class Admin::ScheduleEventPassesController < Admin::BaseController
  before_action :set_user, only: [:index, :new, :create]

  def index
    authorize ScheduleEventPass, :index?
    @passes = @user ? @user.schedule_event_passes.order(created_at: :desc)
                    : ScheduleEventPass.order(created_at: :desc).includes(:user)
  end

  def new
    @pass = ScheduleEventPass.new
    authorize(@pass)
  end

  def create
    @pass = ScheduleEventPass.new(pass_params.merge(tenant: Current.tenant))
    @pass.user = @user if @user
    authorize(@pass)

    if @pass.save
      redirect_back_or_to admin_schedule_event_passes_path, notice: t(".notice")
    else
      flash.now[:alert] = @pass.errors.full_messages.to_sentence
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    @pass = ScheduleEventPass.find(params[:id])
    authorize(@pass)
    @pass.destroy!
    redirect_back_or_to admin_schedule_event_passes_path, notice: t(".notice")
  end

  private

  def set_user
    @user = User.find(params[:user_id]) if params[:user_id].present?
  end

  def pass_params
    params.require(:schedule_event_pass).permit(:user_id, :credits_remaining, :expires_at)
  end
end
