require "rails_helper"

RSpec.describe ListingInferenceBatch, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:lot) { create(:lot) }

  def build_batch(attrs = {})
    batch = ListingInferenceBatch.new({ lot: lot, status: "pending" }.merge(attrs))
    batch.source_files.attach(
      io: StringIO.new("data"),
      filename: "test.txt",
      content_type: "text/plain"
    ) unless attrs.key?(:skip_attachment)
    batch
  end

  describe "validations" do
    it "requires a lot" do
      batch = build_batch
      batch.lot = nil
      expect(batch).not_to be_valid
      expect(batch.errors[:lot_id]).to be_present
    end

    it "requires a valid status" do
      expect(build_batch(status: "unknown")).not_to be_valid
    end

    it "accepts all valid statuses", :skip_n_plus_one do
      %w[pending processing done failed].each do |status|
        expect(build_batch(status: status)).to be_valid
      end
    end

    it "requires at least one source file" do
      batch = ListingInferenceBatch.new(lot: lot, status: "pending")
      expect(batch).not_to be_valid
      expect(batch.errors[:source_files]).to be_present
    end
  end

  describe "status predicates" do
    %w[pending processing done failed].each do |status|
      it "returns true for ##{status}? when status is #{status}" do
        batch = build_batch(status: status)
        expect(batch.public_send(:"#{status}?")).to be true
      end
    end
  end

  describe "#progress_percent" do
    it "returns 0 when total_count is zero" do
      batch = build_batch
      batch.total_count = 0
      expect(batch.progress_percent).to eq(0)
    end

    it "calculates percentage from processed and failed counts" do
      batch = build_batch
      batch.total_count = 10
      batch.processed_count = 6
      batch.failed_count = 2
      expect(batch.progress_percent).to eq(80.0)
    end
  end

  describe "#name" do
    it "returns 'batch'" do
      expect(build_batch.name).to eq("batch")
    end
  end
end
