class Admin::Listings::VariantsController < Admin::BaseController
  before_action :set_listing

  def create
    option_values_by_option = @listing.options.includes(:option_values).map { |o| o.option_values.to_a }
    combinations = option_values_by_option.reduce([[]]) { |combos, vals| combos.product(vals).map(&:flatten) }

    combinations.each do |combo|
      next if @listing.variants.joins(:variant_option_values)
                       .where(listings_variant_option_values: { option_value_id: combo.map(&:id) })
                       .where("(SELECT COUNT(*) FROM listings_variant_option_values WHERE variant_id = listings_variants.id) = ?", combo.size)
                       .exists?
      variant = @listing.variants.create!
      combo.each { |ov| variant.variant_option_values.create!(option_value: ov) }
    end

    redirect_to edit_admin_listing_path(@listing), notice: "Variants generated."
  end

  private

  def set_listing
    @listing = Listing.find_by!(hashid: params[:listing_hashid])
    authorize(@listing, :update?)
  end
end
