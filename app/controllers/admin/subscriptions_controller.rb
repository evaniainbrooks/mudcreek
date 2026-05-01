class Admin::SubscriptionsController < Admin::BaseController
  before_action :set_subscription, only: %i[show update]

  def show
    prepare_show_assigns
  end

  def create
    @subscription = Subscription.new(subscription_params)
    authorize(@subscription)

    primary_user_id = params.dig(:subscription, :primary_user_id)

    if @subscription.save
      if primary_user_id.present?
        @subscription.subscription_users.create!(
          user_id: primary_user_id,
          primary_contact: true,
          tenant: Current.tenant
        )
      end
      redirect_to admin_subscription_plan_path(@subscription.subscription_plan), notice: "Subscription was successfully created."
    else
      @subscription_plan = @subscription.subscription_plan || SubscriptionPlan.find_by(id: subscription_params[:subscription_plan_id])
      @users = User.order(:email_address)
      @subscriptions = @subscription_plan&.subscriptions
                                         &.includes(subscription_users: :user)
                                         &.includes(:subscription_plan)
                                         &.order(:status)
      render "admin/subscription_plans/show", status: :unprocessable_content
    end
  end

  def update
    if @subscription.update(subscription_update_params)
      redirect_to admin_subscription_path(@subscription), notice: "Subscription was successfully updated."
    else
      prepare_show_assigns
      render :show, status: :unprocessable_content
    end
  end

  private

  def prepare_show_assigns
    @subscription_user = @subscription.subscription_users.build
    @available_users = User.activated.order(:email_address)
                           .where.not(id: @subscription.users.select(:id))
    @subscription_users = @subscription.subscription_users
                                        .joins(:user)
                                        .where.not(users: { activated_at: nil })
                                        .includes(:user)
    @invoices = @subscription.invoices.order(created_at: :desc)
  end

  def set_subscription
    @subscription = Subscription.find(params[:id])
    authorize(@subscription)
  end

  def subscription_params
    params.expect(subscription: [ :subscription_plan_id, :renews_at ])
  end

  def subscription_update_params
    params.expect(subscription: [ :status, :renews_at, :amount ])
  end
end
