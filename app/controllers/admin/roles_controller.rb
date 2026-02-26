class Admin::RolesController < Admin::BaseController
  before_action :set_role, only: [:destroy]

  def index
    @role = Role.new
    @roles = Role.includes(:users).order(:name)
  end

  def create
    @role = Role.new(role_params)
    if @role.save
      redirect_to admin_roles_path, notice: "Role \"#{@role.name}\" was successfully created."
    else
      @roles = Role.includes(:users).order(:name)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @role.destroy!
    redirect_to admin_roles_path, notice: "Role \"#{@role.name}\" was successfully deleted."
  end

  private

  def set_role
    @role = Role.find(params[:id])
  end

  def role_params
    params.require(:role).permit(:name, :description)
  end
end
