require "rails_helper"
require "rack/test"

RSpec.describe NutritionAnalysis::VisionClient do
  let(:image) { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/sample.jpg"), "image/jpeg") }

  it "returns an error when no client is configured" do
    client = described_class.new(openai_client: nil)
    result = client.analyze(image: image, food_name: "Salad")

    expect(result.success?).to be(false)
    expect(result.error_message).to match(/not configured/i)
  end

  it "returns an error when no image is supplied" do
    client = described_class.new(openai_client: double("client"))
    result = client.analyze(image: nil)

    expect(result.success?).to be(false)
    expect(result.error_message).to include("No image provided")
  end

  it "parses a successful response" do
    response = {
      "choices" => [
        {
          "message" => {
            "content" => [
              {
                "type" => "text",
                "text" => "```json\n{\"food_name\":\"Pasta\",\"macros\":{\"calories\":600,\"protein_g\":22,\"fats_g\":18,\"carbs_g\":75}}\n```"
              }
            ]
          }
        }
      ]
    }

    fake_client = double("OpenAIClient")
    allow(fake_client).to receive(:chat).and_return(response)

    result = described_class.new(openai_client: fake_client).analyze(image: image)

    expect(result).to be_success
    expect(result.food_name).to eq("Pasta")
    expect(result.macros[:calories]).to eq(600)
  end

  it "returns an error if macros contain non numeric values" do
    response = {
      "choices" => [
        {
          "message" => {
            "content" => [
              {
                "type" => "text",
                "text" => '{"food_name":"Pasta","macros":{"calories":"about 500","protein_g":22,"fats_g":18,"carbs_g":75}}'
              }
            ]
          }
        }
      ]
    }

    fake_client = double("OpenAIClient")
    allow(fake_client).to receive(:chat).and_return(response)

    result = described_class.new(openai_client: fake_client).analyze(image: image)

    expect(result.success?).to be(false)
    expect(result.error_message).to match(/interpret the nutrition info|went wrong/i)
  end
end
