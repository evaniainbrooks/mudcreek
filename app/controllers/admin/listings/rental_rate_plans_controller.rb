class Admin::Listings::RentalRatePlansController < Admin::BaseController
  before_action :set_listing

  def create
    @rate_plan = @listing.rental_rate_plans.new(rate_plan_params)
    authorize(@rate_plan)
    if @rate_plan.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append("rental-rate-plans", partial: "admin/listings/rental_rate_plans/rate_plan", locals: { rate_plan: @rate_plan }),
            turbo_stream.replace("rental-rate-plan-form", partial: "admin/listings/rental_rate_plans/form", locals: { listing: @listing, rate_plan: Listings::RentalRatePlan.new })
          ]
        end
        format.html { redirect_to edit_admin_listing_path(@listing) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("rental-rate-plan-form", partial: "admin/listings/rental_rate_plans/form", locals: { listing: @listing, rate_plan: @rate_plan })
        end
        format.html { redirect_to edit_admin_listing_path(@listing) }
      end
    end
  end

  def destroy
    @rate_plan = @listing.rental_rate_plans.find(params[:id])
    authorize(@rate_plan)
    @rate_plan.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(ActionView::RecordIdentifier.dom_id(@rate_plan)) }
      format.html { redirect_to edit_admin_listing_path(@listing) }
    end
  end

  private

  def set_listing
    @listing = Listing.find_by!(hashid: params[:listing_hashid])
  end

  def rate_plan_params
    params.require(:listings_rental_rate_plan).permit(:label, :duration_minutes, :price)
  end
end
