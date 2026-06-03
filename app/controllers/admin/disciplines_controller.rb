class Admin::DisciplinesController < Admin::BaseController
  before_action :set_discipline, only: [ :show, :edit, :update, :destroy ]

  def index
    authorize(Discipline)
    @disciplines = Discipline.ordered.includes(:ranks)
  end

  def show
    @ranks = @discipline.ranks.ordered
  end

  def new
    @discipline = Discipline.new
    authorize(@discipline)
  end

  def create
    @discipline = Discipline.new(discipline_params)
    authorize(@discipline)

    if @discipline.save
      redirect_to admin_discipline_path(@discipline), notice: t(".notice")
    else
      flash.now[:alert] = @discipline.errors.full_messages.to_sentence
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @discipline.update(discipline_params)
      redirect_to admin_discipline_path(@discipline), notice: t(".notice")
    else
      flash.now[:alert] = @discipline.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @discipline.destroy!
    redirect_to admin_disciplines_path, notice: t(".notice")
  end

  private

  def set_discipline
    @discipline = Discipline.find(params[:id])
    authorize(@discipline)
  end

  def discipline_params
    params.require(:discipline).permit(:name, :kids)
  end
end
