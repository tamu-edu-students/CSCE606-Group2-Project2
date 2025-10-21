require "rails_helper"

RSpec.describe MeasurementParamsNormalizer do
  describe ".normalize" do
    it "keeps metric inputs as-is" do
      params = described_class.normalize(
        sex: "female",
        date_of_birth: "1990-01-01",
        height_input: "170",
        weight_input: "62",
        measurement_system: "metric",
        activity_level: "moderately_active",
        goal_type: "maintain"
      )

      expect(params[:height_cm]).to eq(170)
      expect(params[:weight_kg]).to eq(62.0)
      expect(params).not_to have_key(:height_input)
      expect(params).not_to have_key(:weight_input)
      expect(params).not_to have_key(:measurement_system)
    end

    it "converts imperial inputs when metric blank" do
      params = described_class.normalize(
        height_input: "5'10\"",
        weight_input: "180 lbs",
        measurement_system: "imperial"
      )

      expect(params[:height_cm]).to eq(178)
      expect(params[:weight_kg]).to be_within(0.1).of(81.6)
    end

    it "handles inches-only entries" do
      params = described_class.normalize(
        height_input: "72 in",
        measurement_system: "imperial"
      )

      expect(params[:height_cm]).to eq(183)
    end

    it "interprets decimal feet" do
      params = described_class.normalize(
        height_input: "5.5",
        measurement_system: "imperial"
      )

      expect(params[:height_cm]).to eq(168)
    end
  end
end
