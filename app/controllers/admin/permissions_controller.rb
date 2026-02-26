class Admin::PermissionsController < Admin::BaseController
  before_action :set_role
  before_action :set_permission, only: [:destroy]

  def index
    authorize(Permission)
    @permission = @role.permissions.new
    @permissions = @role.permissions.order(:resource, :action)
  end

  def create
    @permission = @role.permissions.new(permission_params)
    authorize(@permission)
    if @permission.save
      redirect_to admin_role_permissions_path(@role), notice: "Permission was successfully added."
    else
      redirect_to admin_role_permissions_path(@role), alert: @permission.errors.full_messages.to_sentence
    end
  end

  def destroy
    @permission.destroy!
    redirect_to admin_role_permissions_path(@role), notice: "Permission was successfully removed."
  end

  private

  def set_role
    @role = Role.find(params[:role_id])
  end

  def set_permission
    @permission = @role.permissions.find(params[:id])
    authorize(@permission)
  end

  def permission_params
    params.require(:permission).permit(:resource, :action)
  end
end
