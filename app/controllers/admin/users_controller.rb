class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :update]

  def index
    authorize(User)
    @tab = params[:tab].presence_in(%w[users kids birthdays]) || "users"

    case @tab
    when "users"
      load_users_tab
    when "kids"
      load_kids_tab
    when "birthdays"
      load_birthdays_tab
    end
  end

  def show
    @roles = Role.order(:name)
  end

  def new
    @user = User.new
    authorize(@user)
    @roles = Role.order(:name)
  end

  def create
    @user = User.new(new_user_params)
    @user.created_by_id = Current.user.id
    authorize(@user)

    if @user.save
      redirect_to admin_user_path(@user), notice: "User was successfully created."
    else
      @roles = Role.order(:name)
      render :new, status: :unprocessable_content
    end
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

  def load_users_tab
    @roles = Role.order(:name)
    @filter_total = User.count
    @q = User.ransack(params[:q])
    scope = @q.result.includes(:role).order(id: :asc)
    @filter_count = scope.count
    @pagy, @users = pagy(:keyset, scope)
  end

  def load_kids_tab
    @filter_total = Kid.count
    @q = Kid.ransack(params[:q])
    scope = @q.result.includes(:user).order(:name)
    @filter_count = scope.count
    @kids = scope
  end

  def load_birthdays_tab
    today = Date.current
    window_end = today + 30.days

    @birthday_entries = upcoming_birthdays(today, window_end)
  end

  def upcoming_birthdays(today, window_end)
    entries = []

    User.where.not(birthdate: nil).includes(:role).find_each do |user|
      next_bday = next_birthday(user.birthdate, today)
      entries << { type: :user, record: user, next_birthday: next_bday } if next_bday <= window_end
    end

    if Current.tenant.features.kids?
      Kid.includes(:user).find_each do |kid|
        next_bday = next_birthday(kid.birthdate, today)
        entries << { type: :kid, record: kid, next_birthday: next_bday } if next_bday <= window_end
      end
    end

    entries.sort_by { it[:next_birthday] }
  end

  def next_birthday(birthdate, today)
    this_year = begin
      Date.new(today.year, birthdate.month, birthdate.day)
    rescue Date::Error
      Date.new(today.year, 3, 1) # Feb 29 → Mar 1 on non-leap years
    end
    return this_year if this_year >= today

    begin
      Date.new(today.year + 1, birthdate.month, birthdate.day)
    rescue Date::Error
      Date.new(today.year + 1, 3, 1)
    end
  end

  def new_user_params
    params.require(:user).permit(:first_name, :last_name, :email_address, :birthdate, :password, :password_confirmation, :role_id)
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email_address, :birthdate, :role_id,
                                 kids_attributes: [ :id, :name, :birthdate, :_destroy ])
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
