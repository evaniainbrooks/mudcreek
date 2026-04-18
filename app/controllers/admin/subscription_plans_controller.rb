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
      redirect_to admin_subscription_plans_path, notice: "\"#{@subscription_plan.name}\" was successfully created."
    else
      @subscription_plans = SubscriptionPlan.order(:name)
      render :index, status: :unprocessable_content
    end
  end

  def destroy
    @subscription_plan.destroy!
    redirect_to admin_subscription_plans_path, notice: "\"#{@subscription_plan.name}\" was successfully deleted."
  rescue ActiveRecord::DeleteRestrictionError
    redirect_to admin_subscription_plans_path, alert: "Cannot delete a plan with active subscriptions."
  end

  private

  def set_subscription_plan
    @subscription_plan = SubscriptionPlan.find(params[:id])
    authorize(@subscription_plan)
  end

  def subscription_plan_params
    params.expect(subscription_plan: [ :name, :description, :amount, :kind ])
  end
end
