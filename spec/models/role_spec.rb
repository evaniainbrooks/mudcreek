require "rails_helper"

RSpec.describe Role, type: :model do
  before do
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:role) { Role.create!(name: "test_role", description: "A test role") }

  describe "#grant_all_permissions!" do
    def valid_actions_for(resource)
      policy_class = "#{resource}Policy".safe_constantize
      Permission::ACTIONS.select { |action| policy_class&.method_defined?(:"#{action}?") }
    end

    it "creates a permission for every valid resource/action combination" do
      role.grant_all_permissions!

      expected = Permission::RESOURCES.sum { |r| valid_actions_for(r).size }
      expect(role.permissions.count).to eq(expected)
    end

    it "covers every resource" do
      role.grant_all_permissions!

      expect(role.permissions.pluck(:resource).uniq).to match_array(Permission::RESOURCES)
    end

    it "covers only policy-defined actions for each resource" do
      role.grant_all_permissions!

      permissions_by_resource = role.permissions.pluck(:resource, :action).group_by(&:first)
      Permission::RESOURCES.each do |resource|
        expect(permissions_by_resource[resource]&.map(&:last)).to match_array(valid_actions_for(resource))
      end
    end

    it "is idempotent" do
      role.grant_all_permissions!

      expect { role.grant_all_permissions! }.not_to change { role.permissions.count }
    end
  end
end
