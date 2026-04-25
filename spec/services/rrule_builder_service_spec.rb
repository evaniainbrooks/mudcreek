require "rails_helper"

RSpec.describe RruleBuilderService do
  describe ".build" do
    context "when freq is blank" do
      it "returns nil" do
        expect(described_class.build({ freq: "" })).to be_nil
      end
    end

    context "when params are nil" do
      it "returns nil" do
        expect(described_class.build(nil)).to be_nil
      end
    end

    context "with DAILY frequency" do
      it "returns a DAILY rule" do
        expect(described_class.build({ freq: "DAILY" })).to eq("FREQ=DAILY")
      end

      it "includes INTERVAL when greater than 1" do
        expect(described_class.build({ freq: "DAILY", interval: "3" })).to eq("FREQ=DAILY;INTERVAL=3")
      end

      it "omits INTERVAL when 1" do
        expect(described_class.build({ freq: "DAILY", interval: "1" })).to eq("FREQ=DAILY")
      end
    end

    context "with WEEKLY frequency" do
      it "returns a WEEKLY rule" do
        expect(described_class.build({ freq: "WEEKLY" })).to eq("FREQ=WEEKLY")
      end

      it "includes BYDAY when days are selected" do
        result = described_class.build({ freq: "WEEKLY", byday: %w[MO WE FR] })
        expect(result).to eq("FREQ=WEEKLY;BYDAY=MO,WE,FR")
      end

      it "omits BYDAY when no days are selected" do
        result = described_class.build({ freq: "WEEKLY", byday: [] })
        expect(result).to eq("FREQ=WEEKLY")
      end

      it "combines INTERVAL and BYDAY" do
        result = described_class.build({ freq: "WEEKLY", interval: "2", byday: %w[TU TH] })
        expect(result).to eq("FREQ=WEEKLY;INTERVAL=2;BYDAY=TU,TH")
      end
    end

    context "with MONTHLY frequency" do
      it "returns a MONTHLY rule" do
        expect(described_class.build({ freq: "MONTHLY" })).to eq("FREQ=MONTHLY")
      end

      it "ignores BYDAY for non-weekly frequencies" do
        result = described_class.build({ freq: "MONTHLY", byday: %w[MO] })
        expect(result).to eq("FREQ=MONTHLY")
      end
    end

    context "with YEARLY frequency" do
      it "returns a YEARLY rule" do
        expect(described_class.build({ freq: "YEARLY" })).to eq("FREQ=YEARLY")
      end
    end

    context "with an UNTIL date" do
      it "formats the date as YYYYMMDD" do
        result = described_class.build({ freq: "WEEKLY", until: "2026-12-31" })
        expect(result).to eq("FREQ=WEEKLY;UNTIL=20261231")
      end

      it "omits UNTIL when blank" do
        result = described_class.build({ freq: "DAILY", until: "" })
        expect(result).to eq("FREQ=DAILY")
      end
    end

    context "in advanced mode" do
      it "returns the raw string directly" do
        raw = "FREQ=WEEKLY;BYDAY=MO,WE,FR;COUNT=10"
        result = described_class.build({ advanced: "1", raw: raw })
        expect(result).to eq(raw)
      end

      it "returns nil when raw is blank" do
        expect(described_class.build({ advanced: "1", raw: "" })).to be_nil
      end
    end
  end

  describe ".parse" do
    context "when rrule is blank" do
      it "returns defaults with empty freq" do
        result = described_class.parse(nil)
        expect(result).to include(freq: "", interval: 1, byday: [], until: "", advanced: false, raw: "")
      end

      it "handles an empty string" do
        result = described_class.parse("")
        expect(result[:freq]).to eq("")
      end
    end

    context "with a DAILY rule" do
      it "parses freq and defaults" do
        result = described_class.parse("FREQ=DAILY")
        expect(result).to include(freq: "DAILY", interval: 1, byday: [], until: "", advanced: false)
      end

      it "parses INTERVAL" do
        result = described_class.parse("FREQ=DAILY;INTERVAL=3")
        expect(result[:interval]).to eq(3)
      end
    end

    context "with a WEEKLY rule" do
      it "parses BYDAY into an array" do
        result = described_class.parse("FREQ=WEEKLY;BYDAY=MO,WE,FR")
        expect(result[:byday]).to eq(%w[MO WE FR])
      end

      it "returns empty byday when absent" do
        result = described_class.parse("FREQ=WEEKLY")
        expect(result[:byday]).to eq([])
      end
    end

    context "with an UNTIL date" do
      it "converts YYYYMMDD to YYYY-MM-DD" do
        result = described_class.parse("FREQ=DAILY;UNTIL=20261231")
        expect(result[:until]).to eq("2026-12-31")
      end
    end

    context "with an unsupported FREQ" do
      it "falls back to advanced mode with the raw string" do
        raw    = "FREQ=HOURLY;INTERVAL=2"
        result = described_class.parse(raw)
        expect(result).to include(advanced: true, raw: raw, freq: "")
      end
    end
  end

  describe "round-trip" do
    it "parse then build returns the original string" do
      original = "FREQ=WEEKLY;INTERVAL=2;BYDAY=TU,TH;UNTIL=20261231"
      parsed   = described_class.parse(original)
      rebuilt  = described_class.build(parsed)
      expect(rebuilt).to eq(original)
    end
  end
end
