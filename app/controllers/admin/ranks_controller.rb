class Admin::RanksController < Admin::BaseController
  before_action :set_discipline

  def create
    @rank = @discipline.ranks.new(rank_params)
    authorize(@rank)

    if @rank.save
      redirect_to admin_discipline_path(@discipline), notice: t(".notice")
    else
      redirect_to admin_discipline_path(@discipline), alert: @rank.errors.full_messages.to_sentence
    end
  end

  def edit
    @rank = @discipline.ranks.find(params[:id])
    authorize(@rank)
  end

  def update
    @rank = @discipline.ranks.find(params[:id])
    authorize(@rank)

    if @rank.update(rank_params)
      redirect_to admin_discipline_path(@discipline), notice: t(".notice")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @rank = @discipline.ranks.find(params[:id])
    authorize(@rank)
    @rank.destroy!
    redirect_to admin_discipline_path(@discipline), notice: t(".notice")
  end

  private

  def set_discipline
    @discipline = Discipline.find(params[:discipline_id])
  end

  def rank_params
    params.require(:rank).permit(:name, :position)
  end
end
