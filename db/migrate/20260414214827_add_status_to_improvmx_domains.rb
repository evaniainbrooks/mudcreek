class AddStatusToImprovmxDomains < ActiveRecord::Migration[8.1]
  def change
    create_enum :improvmx_domain_status, %w[unchecked verified failed]

    add_column :improvmx_domains, :status, :enum,
      enum_type: :improvmx_domain_status,
      default: "unchecked",
      null: false

    add_column :improvmx_domains, :check_data, :jsonb, default: {}, null: false
  end
end
