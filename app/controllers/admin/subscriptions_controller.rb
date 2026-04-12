class Admin::SubscriptionsController < Admin::BaseController
  before_action :set_subscription, only: %i[show update]

  def index
    authorize(Subscription)
    @q = Subscription.ransack(params[:q])
    @subscriptions = @q.result.includes(:user, :subscription_plan).order(created_at: :desc)
  end

  def show
  end

  def new
    @subscription = Subscription.new
    authorize(@subscription)
    @users  = User.order(:email_address)
    @plans  = SubscriptionPlan.order(:name)
  end

  def create
    @subscription = Subscription.new(subscription_params)
    authorize(@subscription)

    if @subscription.save
      redirect_to admin_subscription_path(@subscription), notice: "Subscription was successfully created."
    else
      @users = User.order(:email_address)
      @plans = SubscriptionPlan.order(:name)
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @subscription.update(subscription_update_params)
      redirect_to admin_subscription_path(@subscription), notice: "Subscription was successfully updated."
    else
      render :show, status: :unprocessable_content
    end
  end

  private

  def set_subscription
    @subscription = Subscription.find(params[:id])
    authorize(@subscription)
  end

  def subscription_params
    params.expect(subscription: [ :user_id, :subscription_plan_id, :renews_at ])
  end

  def subscription_update_params
    params.expect(subscription: [ :status, :renews_at ])
  end
end
