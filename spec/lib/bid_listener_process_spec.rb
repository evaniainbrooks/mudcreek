require "rails_helper"

RSpec.describe BidListenerProcess do
  let(:process) { described_class.new }

  before do
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
    allow(process).to receive(:sleep)
  end

  # Helper: stub BidListener.start to set @stop after a given number of calls
  def stub_listener(stop_after: 1, error_on: nil)
    call_count = 0
    allow(BidListener).to receive(:start) do
      call_count += 1
      raise error_on if error_on && call_count == 1
      process.instance_variable_set(:@stop, true) if call_count >= stop_after
    end
    call_count
  end

  # ------------------------------------------------------------------ #
  describe "#start" do
    it "calls BidListener.start" do
      stub_listener(stop_after: 1)

      expect(BidListener).to receive(:start).at_least(:once)

      process.start
    end

    it "logs a starting message" do
      stub_listener(stop_after: 1)

      expect(Rails.logger).to receive(:info).with(/Starting/)

      process.start
    end

    it "logs a stopped message when the loop exits" do
      stub_listener(stop_after: 1)

      expect(Rails.logger).to receive(:info).with(/Stopped/)

      process.start
    end

    context "when BidListener.start raises an error" do
      before { stub_listener(error_on: RuntimeError.new("connection lost")) }

      it "logs the error" do
        expect(Rails.logger).to receive(:error).with(/connection lost/)

        process.start
      end

      it "sleeps before restarting" do
        expect(process).to receive(:sleep).with(2)

        process.start
      end

      it "restarts BidListener after the error" do
        call_count = 0
        allow(BidListener).to receive(:start) do
          call_count += 1
          if call_count == 1
            raise RuntimeError, "oops"
          else
            process.instance_variable_set(:@stop, true)
          end
        end

        process.start

        expect(call_count).to eq(2)
      end
    end

    context "when @stop is set before a restart" do
      it "does not restart after an error" do
        allow(BidListener).to receive(:start) do
          process.instance_variable_set(:@stop, true)
          raise RuntimeError, "oops"
        end

        process.start

        expect(BidListener).to have_received(:start).once
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe ".run" do
    it "instantiates and calls start" do
      instance = instance_double(described_class)
      allow(described_class).to receive(:new).and_return(instance)
      expect(instance).to receive(:start)

      described_class.run
    end
  end
end
