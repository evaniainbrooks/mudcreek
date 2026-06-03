class Admin::SubscriptionPlansController < Admin::BaseController
  before_action :set_subscription_plan, only: %i[show destroy]

  def index
    authorize(SubscriptionPlan)
    @subscription_plan = SubscriptionPlan.new
    @subscription_plans = SubscriptionPlan.order(:name)
  end

  def show
    @subscription = Subscription.new(subscription_plan: @subscription_plan)
    @users = User.order(:email_address)
    @subscriptions = @subscription_plan.subscriptions
                                       .includes(subscription_users: :user)
                                       .includes(:subscription_plan)
                                       .order(:status)
  end

  def create
    @subscription_plan = SubscriptionPlan.new(subscription_plan_params)
    authorize(@subscription_plan)

    if @subscription_plan.save
      redirect_to admin_subscription_plans_path, notice: t(".notice", name: @subscription_plan.name)
    else
      @subscription_plans = SubscriptionPlan.order(:name)
      flash.now[:alert] = @subscription_plan.errors.full_messages.to_sentence
      render :index, status: :unprocessable_content
    end
  end

  def destroy
    @subscription_plan.destroy!
    redirect_to admin_subscription_plans_path, notice: t(".notice", name: @subscription_plan.name)
  rescue ActiveRecord::DeleteRestrictionError
    redirect_to admin_subscription_plans_path, alert: t(".alert")
  end

  private

  def set_subscription_plan
    @subscription_plan = SubscriptionPlan.find(params[:id])
    authorize(@subscription_plan)
  end

  def subscription_plan_params
    params.expect(subscription_plan: [ :name, :description, :amount, :subscription_type ])
  end
end
