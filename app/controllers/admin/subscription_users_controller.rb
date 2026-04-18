class Admin::SubscriptionUsersController < Admin::BaseController
  before_action :set_subscription

  def create
    @subscription_user = @subscription.subscription_users.build(subscription_user_params)
    authorize(@subscription_user)

    if @subscription_user.save
      redirect_to admin_subscription_path(@subscription), notice: "User added to subscription."
    else
      redirect_to admin_subscription_path(@subscription),
        alert: @subscription_user.errors.full_messages.to_sentence
    end
  end

  def destroy
    @subscription_user = @subscription.subscription_users.find(params[:id])
    authorize(@subscription_user)

    if @subscription_user.primary_contact?
      redirect_to admin_subscription_path(@subscription), alert: "Cannot remove the primary contact."
    else
      @subscription_user.destroy!
      redirect_to admin_subscription_path(@subscription), notice: "User removed from subscription."
    end
  end

  private

  def set_subscription
    @subscription = Subscription.find(params[:subscription_id])
  end

  def subscription_user_params
    params.expect(subscription_user: [ :user_id ])
  end
end
