class ValidateListingInferenceBatchLotIdNotNull < ActiveRecord::Migration[8.1]
  def up
    validate_check_constraint :listing_inference_batches, name: "listing_inference_batches_lot_id_null"
    change_column_null :listing_inference_batches, :lot_id, false
    remove_check_constraint :listing_inference_batches, name: "listing_inference_batches_lot_id_null"
  end

  def down
    add_check_constraint :listing_inference_batches, "lot_id IS NOT NULL", name: "listing_inference_batches_lot_id_null", validate: false
    change_column_null :listing_inference_batches, :lot_id, true
  end
end
