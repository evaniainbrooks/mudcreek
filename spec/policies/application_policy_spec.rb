require "rails_helper"

RSpec.describe ApplicationPolicy do
  before { Current.tenant = create(:tenant, default: true) }

  let(:role)   { create(:role) }
  let(:user)   { create(:user, role:) }
  let(:record) { create(:user) }
  let(:policy) { described_class.new(user, record) }

  describe ".actions" do
    describe "without a block" do
      let(:subclass) { Class.new(described_class) { actions :show } }

      it "generates a method that delegates to permitted?" do
        instance = subclass.new(user, record)
        allow(instance).to receive(:permitted?).with(:show).and_return(true)
        expect(instance.show?).to be(true)
      end
    end

    describe "with a block" do
      let(:subclass) { Class.new(described_class) { actions(:show) { true } } }

      it "generates the method using the block" do
        expect(subclass.new(user, record).show?).to be(true)
      end
    end
  end

  describe "auto-aliasing" do
    it "aliases new? to create? when :create is declared" do
      subclass = Class.new(described_class) { actions :create }
      instance = subclass.new(user, record)
      allow(instance).to receive(:permitted?).with(:create).and_return(true)
      expect(instance.new?).to be(true)
    end

    it "aliases edit? to update? when :update is declared" do
      subclass = Class.new(described_class) { actions :update }
      instance = subclass.new(user, record)
      allow(instance).to receive(:permitted?).with(:update).and_return(true)
      expect(instance.edit?).to be(true)
    end

    it "aliases new? to a custom create? block" do
      subclass = Class.new(described_class) { actions(:create) { false } }
      expect(subclass.new(user, record).new?).to be(false)
    end

    it "aliases edit? to a custom update? block" do
      subclass = Class.new(described_class) { actions(:update) { false } }
      expect(subclass.new(user, record).edit?).to be(false)
    end
  end

  describe "direct definition guard" do
    it "raises when create? is defined directly in a subclass" do
      expect do
        Class.new(described_class) { def create? = true }
      end.to raise_error(RuntimeError, /Use `actions :create`/)
    end

    it "raises when update? is defined directly in a subclass" do
      expect do
        Class.new(described_class) { def update? = true }
      end.to raise_error(RuntimeError, /Use `actions :update`/)
    end

    it "does not raise when :create is declared via actions" do
      expect { Class.new(described_class) { actions :create } }.not_to raise_error
    end

    it "does not raise when :update is declared via actions" do
      expect { Class.new(described_class) { actions :update } }.not_to raise_error
    end
  end

  describe "default actions" do
    %w[index show create update destroy].each do |action|
      context "##{action}?" do
        context "when the user has the permission" do
          before { create(:permission, role:, resource: record.class.name, action:) }

          it "returns true" do
            expect(policy.public_send(:"#{action}?")).to be(true)
          end
        end

        context "when the user does not have the permission" do
          it "returns false" do
            expect(policy.public_send(:"#{action}?")).to be(false)
          end
        end
      end
    end

    it "new? delegates to create?" do
      allow(policy).to receive(:create?).and_return(true)
      expect(policy.new?).to be(true)
    end

    it "edit? delegates to update?" do
      allow(policy).to receive(:update?).and_return(true)
      expect(policy.edit?).to be(true)
    end
  end

  describe "#permitted?" do
    context "when the user has no role" do
      let(:user) { create(:user) }

      it "returns false" do
        expect(policy.send(:permitted?, :show)).to be(false)
      end
    end

    context "when the user's role lacks the permission" do
      it "returns false" do
        expect(policy.send(:permitted?, :show)).to be(false)
      end
    end

    context "when the user's role has the permission" do
      before { create(:permission, role:, resource: record.class.name, action: "show") }

      it "returns true" do
        expect(policy.send(:permitted?, :show)).to be(true)
      end
    end

    context "when the record is a class" do
      let(:policy) { described_class.new(user, User) }

      before { create(:permission, role:, resource: "User", action: "index") }

      it "uses the class name as the resource" do
        expect(policy.send(:permitted?, :index)).to be(true)
      end
    end
  end
end
