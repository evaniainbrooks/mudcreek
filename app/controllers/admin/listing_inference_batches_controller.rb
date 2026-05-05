class Admin::ListingInferenceBatchesController < Admin::BaseController
  before_action :set_batch, only: [ :show ]

  def new
    @batch = ListingInferenceBatch.new
    authorize(@batch)
    @lots = Lot.order(:name)
  end

  def create
    @batch = ListingInferenceBatch.new(batch_params)
    authorize(@batch)
    if @batch.save
      ProcessListingInferenceBatchJob.perform_later(@batch.id)
      redirect_to admin_listing_inference_batch_path(@batch), notice: t(".notice")
    else
      @lots = Lot.order(:name)
      render :new, status: :unprocessable_content
    end
  end

  def show; end

  private

  def set_batch
    @batch = ListingInferenceBatch.find_by!(hashid: params[:hashid])
    authorize(@batch)
  end

  def batch_params
    params.require(:listing_inference_batch).permit(:lot_id, source_files: [])
  end
end
