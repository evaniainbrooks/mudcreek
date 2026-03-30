class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :update]

  def index
    authorize(User)
    @roles = Role.order(:name)
    @filter_total = User.count
    @q = User.ransack(params[:q])
    scope = @q.result.includes(:role).order(id: :asc)
    @filter_count = scope.count
    @pagy, @users = pagy(:keyset, scope)
  end

  def show
    @roles = Role.order(:name)
  end

  def update
    @user.assign_attributes(user_params)
    @user.activated_at = activated_at_from_params

    if @user.save
      update_verification_from_params
      redirect_to admin_user_path(@user), notice: "User updated."
    else
      @roles = Role.order(:name)
      render :show, status: :unprocessable_content
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
    authorize(@user)
  end

  def user_params
    params.expect(user: [:first_name, :last_name, :email_address, :role_id])
  end

  def update_verification_from_params
    status = params.dig(:user, :verification_status)
    return if status.blank?

    verification = @user.verification || Users::Verification.new(user: @user)
    verification.status = status
    verification.validated_by = status == "validated" ? Current.user : nil
    verification.save!
  end

  def activated_at_from_params
    if params.dig(:user, :activated) == "1"
      @user.activated_at || Time.current
    else
      nil
    end
  end
end
