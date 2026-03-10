require "rails_helper"

RSpec.describe BidListener do
  let(:listener) { described_class.new }
  let(:conn)     { instance_double(PG::Connection) }

  before do
    allow(listener).to receive(:with_connection).and_yield(conn)
    allow(conn).to receive(:exec)
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
  end

  # ------------------------------------------------------------------ #
  describe "#run" do
    before do
      # Break the infinite loop after the first wait_for_notify call
      call_count = 0
      allow(conn).to receive(:wait_for_notify) do |_timeout, &block|
        call_count += 1
        raise StopIteration if call_count > 1
        block&.call(described_class::CHANNEL, 42, '{"state":"placed"}')
      end
      allow(listener).to receive(:handle)
    end

    it "issues LISTEN on the bid_events channel" do
      expect(conn).to receive(:exec).with("LISTEN #{described_class::CHANNEL}")

      listener.run rescue StopIteration
    end

    it "calls wait_for_notify with the configured timeout" do
      expect(conn).to receive(:wait_for_notify).with(described_class::TIMEOUT).at_least(:once)

      listener.run rescue StopIteration
    end

    it "calls handle with the received payload" do
      expect(listener).to receive(:handle).with('{"state":"placed"}')

      listener.run rescue StopIteration
    end

    it "logs that it is listening" do
      expect(Rails.logger).to receive(:info).with(/Listening on/)

      listener.run rescue StopIteration
    end
  end

  # ------------------------------------------------------------------ #
  describe "#handle (private)" do
    let(:payload) do
      JSON.generate(bid_id: 7, auction_listing_id: 3, amount_cents: 2500, state: "placed")
    end

    it "calls on_bid_event with the parsed data" do
      expect(listener).to receive(:on_bid_event).with(
        a_hash_including("bid_id" => 7, "auction_listing_id" => 3,
                         "amount_cents" => 2500, "state" => "placed")
      )

      listener.send(:handle, payload)
    end

    it "logs the event details" do
      allow(listener).to receive(:on_bid_event)
      expect(Rails.logger).to receive(:info).with(/bid_id=7.*state=placed/)

      listener.send(:handle, payload)
    end

    context "when an error is raised during processing" do
      before { allow(listener).to receive(:on_bid_event).and_raise(RuntimeError, "boom") }

      it "does not re-raise the error" do
        expect { listener.send(:handle, payload) }.not_to raise_error
      end

      it "logs the error" do
        expect(Rails.logger).to receive(:error).with(/boom/)

        listener.send(:handle, payload)
      end
    end

    context "when the payload is invalid JSON" do
      it "does not re-raise the error" do
        expect { listener.send(:handle, "not json") }.not_to raise_error
      end

      it "logs the error" do
        expect(Rails.logger).to receive(:error).with(/Error handling payload/)

        listener.send(:handle, "not json")
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "#on_bid_event (private)" do
    let(:data) { { "state" => "placed", "auction_listing_id" => 5 } }

    it "calls BidBroadcastService.call with the data" do
      expect(BidBroadcastService).to receive(:call).with(data)

      listener.send(:on_bid_event, data)
    end
  end

  # ------------------------------------------------------------------ #
  describe "#with_connection (private)" do
    let(:pg_conn) { instance_double(PG::Connection) }
    let(:db_config) do
      { host: "localhost", port: 5432, database: "mudcreek_test",
        username: "postgres", password: nil }
    end

    before do
      allow(ActiveRecord::Base.connection_db_config)
        .to receive(:configuration_hash).and_return(db_config)
      allow(PG).to receive(:connect).and_return(pg_conn)
      allow(pg_conn).to receive(:finish)
    end

    it "connects using the Rails DB config" do
      expect(PG).to receive(:connect).with(
        host:     "localhost",
        port:     5432,
        dbname:   "mudcreek_test",
        user:     "postgres",
        password: nil
      ).and_return(pg_conn)

      listener_without_stub = described_class.new
      listener_without_stub.send(:with_connection) { |_c| }
    end

    it "yields the connection" do
      yielded = nil
      listener_without_stub = described_class.new
      listener_without_stub.send(:with_connection) { |c| yielded = c }

      expect(yielded).to eq(pg_conn)
    end

    it "calls finish on the connection after the block" do
      expect(pg_conn).to receive(:finish)

      listener_without_stub = described_class.new
      listener_without_stub.send(:with_connection) { |_c| }
    end

    it "calls finish even when the block raises" do
      expect(pg_conn).to receive(:finish)

      listener_without_stub = described_class.new
      listener_without_stub.send(:with_connection) { |_c| raise "oops" } rescue nil
    end
  end
end
