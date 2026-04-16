class AddGa4MeasurementIdToTenants < ActiveRecord::Migration[8.0]
  def change
    add_column :tenants, :ga4_measurement_id, :string
  end
end
