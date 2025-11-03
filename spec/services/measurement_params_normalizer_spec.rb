require 'rails_helper'

RSpec.describe MeasurementParamsNormalizer do
  describe '.normalize' do
    it 'keeps metric inputs as-is' do
      params = { height_cm: 180, weight_kg: 75, measurement_system: 'metric' }
      out = described_class.new(params).normalize
      expect(out[:height_cm]).to eq(180)
      expect(out[:weight_kg]).to eq(75)
    end

    it 'converts imperial height in feet and inches to cm' do
      params = { height_input: "5'11\"", measurement_system: 'imperial' }
      out = described_class.new(params).normalize
      expect(out[:height_cm]).to be_within(1).of((5*12+11) * MeasurementParamsNormalizer::CM_PER_INCH)
    end

    it 'converts imperial height given in inches with in suffix' do
      params = { height_input: '71in', measurement_system: 'imperial' }
      out = described_class.new(params).normalize
      expect(out[:height_cm]).to be_within(1).of(71 * MeasurementParamsNormalizer::CM_PER_INCH)
    end

    it 'converts decimal feet to cm' do
      params = { height_input: '5.5', measurement_system: 'imperial' }
      out = described_class.new(params).normalize
      expect(out[:height_cm]).to be_within(1).of((5.5 * 12) * MeasurementParamsNormalizer::CM_PER_INCH)
    end

    it 'parses weight with lbs suffix' do
      params = { weight_input: '150lbs', measurement_system: 'imperial' }
      out = described_class.new(params).normalize
      expect(out[:weight_kg]).to be_within(0.1).of(150 * MeasurementParamsNormalizer::KG_PER_POUND)
    end

    it 'returns nil for invalid numeric inputs' do
      params = { height_input: 'not-a-number', weight_input: 'abc', measurement_system: 'metric' }
      out = described_class.new(params).normalize
      expect(out[:height_cm]).to be_nil
      expect(out[:weight_kg]).to be_nil
    end

    it 'handles non-hash inputs gracefully' do
      out = described_class.new(nil).normalize
      expect(out).to be_a(Hash)
    end
  end
end
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
