class MakeListingInferenceBatchLotIdNotNull < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :listing_inference_batches, "lot_id IS NOT NULL", name: "listing_inference_batches_lot_id_null", validate: false
  end
end
