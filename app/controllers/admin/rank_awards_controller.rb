class Admin::RankAwardsController < Admin::BaseController
  def create
    @rankable = find_rankable
    @rank_award = @rankable.rank_awards.new(rank_award_params.merge(awarded_by: Current.user))
    authorize(@rank_award)

    if @rank_award.save
      redirect_back fallback_location: admin_users_path, notice: "Promotion recorded."
    else
      redirect_back fallback_location: admin_users_path, alert: @rank_award.errors.full_messages.to_sentence
    end
  end

  def destroy
    @rank_award = RankAward.find(params[:id])
    authorize(@rank_award)
    @rank_award.destroy!
    redirect_back fallback_location: admin_users_path, notice: "Promotion removed."
  end

  private

  def find_rankable
    case params.dig(:rank_award, :rankable_type)
    when "User" then User.find(params.dig(:rank_award, :rankable_id))
    when "Kid"  then Kid.find(params.dig(:rank_award, :rankable_id))
    end
  end

  def rank_award_params
    params.require(:rank_award).permit(:rankable_type, :rankable_id, :rank_id, :stripes, :awarded_at, :notes)
  end
end
