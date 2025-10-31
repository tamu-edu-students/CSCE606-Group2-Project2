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

  it "parses responses returned via the alternative output/content path" do
    response = {
      "output" => [
        { "content" => [ { "text" => '{"food_name":"Salad","macros":{"calories":250,"protein_g":8,"fats_g":5,"carbs_g":30}}' } ] }
      ]
    }

    fake_client = double("OpenAIClient")
    allow(fake_client).to receive(:chat).and_return(response)

    result = described_class.new(openai_client: fake_client).analyze(image: image)
    expect(result).to be_success
    expect(result.macros[:calories]).to eq(250)
  end

  it "converts float-like string macro values by rounding" do
    response = {
      "choices" => [
        {
          "message" => {
            "content" => [
              {
                "type" => "text",
                "text" => '{"food_name":"Porridge","macros":{"calories":"123.6","protein_g":"10.2","fats_g":"5.5","carbs_g":"40.4"}}'
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
    expect(result.macros[:calories]).to eq(124) # 123.6 -> 124
    expect(result.macros[:protein_g]).to eq(10)
  end

  it "handles OpenAI client errors gracefully" do
    fake_client = double("OpenAIClient")
    allow(fake_client).to receive(:chat).and_raise(OpenAI::Error.new("boom"))

    result = described_class.new(openai_client: fake_client).analyze(image: image)
    expect(result.success?).to be(false)
    expect(result.error_message).to match(/OpenAI request failed/i)
  end

  it "returns nil and logs when parsing invalid JSON" do
    response = {
      "choices" => [
        {
          "message" => {
            "content" => [
              { "type" => "text", "text" => "not a json {{{" }
            ]
          }
        }
      ]
    }

    fake_client = double("OpenAIClient")
    allow(fake_client).to receive(:chat).and_return(response)

    expect(Rails.logger).to receive(:warn).at_least(:once)
    result = described_class.new(openai_client: fake_client).analyze(image: image)
    expect(result.success?).to be(false)
  end

  it "parses when content is not an array (string content)" do
    response = {
      "choices" => [
        { "message" => { "content" => '{"food_name":"Soup","macros":{"calories":90,"protein_g":3,"fats_g":2,"carbs_g":10}}' } }
      ]
    }

    fake_client = double("OpenAIClient")
    allow(fake_client).to receive(:chat).and_return(response)

    result = described_class.new(openai_client: fake_client).analyze(image: image)
    expect(result).to be_success
    expect(result.food_name).to eq("Soup")
  end

  it "encodes and rewinds non-tempfile IO objects" do
    # Use a plain File object (not UploadedFile) to hit the non-tempfile branch
    f = File.open(Rails.root.join("spec/fixtures/files/sample.jpg"), "rb")
    response = {
      "choices" => [
        { "message" => { "content" => [ { "type" => "text", "text" => '{"food_name":"FilePic","macros":{"calories":10,"protein_g":1,"fats_g":0,"carbs_g":2}}' } ] } }
      ]
    }

    fake_client = double("OpenAIClient")
    allow(fake_client).to receive(:chat).and_return(response)

    result = described_class.new(openai_client: fake_client).analyze(image: f)
    expect(result).to be_success
    f.close
  end

  it "convert_to_integer returns nil for totally invalid values" do
    vc = described_class.new(openai_client: double("c"))
    expect(vc.send(:convert_to_integer, "nope")).to be_nil
  end

  it "returns an error when choices content is an array but contains no text chunk" do
    client = instance_double(OpenAI::Client, chat: {
      "choices" => [
        { "message" => { "content" => [ { "type" => "image", "image_url" => { "url" => "data:image/jpeg;base64,AAA" } } ] } }
      ]
    })

    file = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/sample.jpg"), "image/jpeg")

    vc = described_class.new(openai_client: client)
    result = vc.analyze(image: file)

    expect(result).not_to be_success
    expect(result.error_message).to match(/couldn't interpret|nutrition info/i)
  end

  it "parses when response uses the content->text->value path" do
    response = {
      "content" => [
        { "text" => { "value" => '{"food_name":"Wrap","macros":{"calories":180,"protein_g":8,"fats_g":6,"carbs_g":22}}' } }
      ]
    }

    fake_client = double("OpenAI::Client")
    allow(fake_client).to receive(:chat).and_return(response)

    result = described_class.new(openai_client: fake_client).analyze(image: image)
    expect(result).to be_success
    expect(result.food_name).to eq("Wrap")
  end

  it "uses the tempfile branch when given an UploadedFile" do
    # ensure encode_image handles objects with tempfile correctly
    response = {
      "choices" => [ { "message" => { "content" => [ { "type" => "text", "text" => '{"food_name":"TempPic","macros":{"calories":5,"protein_g":0,"fats_g":0,"carbs_g":1}}' } ] } } ]
    }

    fake_client = double("OpenAIClient")
    allow(fake_client).to receive(:chat).and_return(response)

    file = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/sample.jpg"), "image/jpeg")
    result = described_class.new(openai_client: fake_client).analyze(image: file)
    expect(result).to be_success
    expect(result.food_name).to eq("TempPic")
  end

  it "calls the OpenAI client with expected chat parameters" do
    fake_client = double("OpenAI::Client")
    expect(fake_client).to receive(:chat).with(hash_including(:parameters)).and_return({})

    described_class.new(openai_client: fake_client).analyze(image: image, food_name: "Guess")
  end

  it "handles generic StandardError from the client and returns a friendly error" do
    fake_client = double("OpenAI::Client")
    allow(fake_client).to receive(:chat).and_raise(RuntimeError.new("boom"))

    result = described_class.new(openai_client: fake_client).analyze(image: image)
    expect(result).not_to be_success
    expect(result.error_message).to match(/Something went wrong/i)
  end

  it "builds an OpenAI::Client when OPENAI_API_KEY is present" do
    original = ENV["OPENAI_API_KEY"]
    ENV["OPENAI_API_KEY"] = "test-key-123"
    begin
      fake_client = double("OpenAI::Client")
      expect(OpenAI::Client).to receive(:new).with(access_token: "test-key-123").and_return(fake_client)

      vc = described_class.new
      # private reader - access to verify the client was set
      expect(vc.send(:openai_client)).to eq(fake_client)
    ensure
      ENV["OPENAI_API_KEY"] = original
    end
  end
end
