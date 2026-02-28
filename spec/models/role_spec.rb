require "rails_helper"

RSpec.describe Role, type: :model do
  before do
    Current.tenant = Tenant.create!(key: "test", default: true)
  end

  let(:role) { Role.create!(name: "test_role", description: "A test role") }

  describe "#grant_all_permissions!" do
    it "creates a permission for every resource/action combination" do
      role.grant_all_permissions!

      expect(role.permissions.count).to eq(Permission::RESOURCES.size * Permission::ACTIONS.size)
    end

    it "covers every resource" do
      role.grant_all_permissions!

      expect(role.permissions.pluck(:resource).uniq).to match_array(Permission::RESOURCES)
    end

    it "covers every action for each resource" do
      role.grant_all_permissions!

      Permission::RESOURCES.each do |resource|
        expect(role.permissions.where(resource: resource).pluck(:action)).to match_array(Permission::ACTIONS)
      end
    end

    it "is idempotent" do
      role.grant_all_permissions!

      expect { role.grant_all_permissions! }.not_to change { role.permissions.count }
    end
  end
end
