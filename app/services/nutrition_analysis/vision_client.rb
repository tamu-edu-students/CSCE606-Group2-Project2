require "json"
require "base64"
require "openai"

module NutritionAnalysis
  class VisionClient
    Analysis = Struct.new(:success?, :food_name, :macros, :error_message, keyword_init: true)

    DEFAULT_MODEL = ENV.fetch("OPENAI_VISION_MODEL", "gpt-4o-mini").freeze

    def initialize(openai_client: build_client)
      @openai_client = openai_client
    end

    def analyze(image:, food_name: nil)
      return error("No image provided") unless image.present?
      return error("OpenAI API key is not configured.") unless client_available?

      encoded = encode_image(image)
      response = request_analysis(encoded, food_name)
      parsed = parse_response(response)

      if parsed
        Analysis.new(
          success?: true,
          food_name: parsed[:food_name],
          macros: parsed[:macros]
        )
      else
        error("We couldn't interpret the nutrition info from the AI response.")
      end
    rescue ::OpenAI::Error => e
      error("OpenAI request failed: #{e.message}")
    rescue StandardError => e
      Rails.logger.error("VisionClient failure: #{e.class} #{e.message}")
      error("Something went wrong while analyzing the photo.")
    ensure
      rewound(image)
    end

    private

    attr_reader :openai_client

    def client_available?
      openai_client.present?
    end

    def build_client
      return nil unless ENV["OPENAI_API_KEY"].present?

      OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
    end

    def request_analysis(encoded_image, food_name)
      prompt = <<~PROMPT
        You are a nutrition expert. Analyze the provided food photo and respond in strict JSON.
        Required keys:
        {
          "food_name": "descriptive name",
          "macros": {
            "calories": integer,
            "protein_g": integer,
            "fats_g": integer,
            "carbs_g": integer
          }
        }
        #{food_name.present? ? "The user suggests it might be: #{food_name}." : "No user suggestion provided."}
        Do not include any other text.
      PROMPT

      openai_client.chat(
        parameters: {
          model: DEFAULT_MODEL,
          messages: [
            {
              role: "system",
              content: "You are a nutrition expert who replies with strict JSON only."
            },
            {
              role: "user",
              content: [
                { type: "text", text: prompt },
                {
                  type: "image_url",
                  image_url: {
                    url: "data:image/jpeg;base64,#{encoded_image}"
                  }
                }
              ]
            }
          ]
        }
      )
    end

    def parse_response(response)
      raw = fetch_text_response(response)
      return unless raw

      cleaned = strip_code_fences(raw)
      data = JSON.parse(cleaned, symbolize_names: true)
      macros = data.fetch(:macros, {})

      converted_macros = normalize_macros(macros)
      return unless converted_macros

      {
        food_name: data[:food_name],
        macros: converted_macros
      }
    rescue JSON::ParserError => e
      Rails.logger.warn("Failed to parse OpenAI response: #{e.message} -- #{raw}")
      nil
    end

    def fetch_text_response(response)
      if (choices = response["choices"])
        content = choices.dig(0, "message", "content")
        if content.is_a?(Array)
          text_chunk = content.find { |item| item["type"] == "text" }
          text_chunk ? text_chunk["text"] : nil
        else
          content
        end
      else
        response.dig("output", 0, "content", 0, "text") ||
          response.dig("content", 0, "text", "value")
      end
  end

  def encode_image(image)
      io =
        if image.respond_to?(:tempfile)
          image.tempfile
        else
          image
        end

      io.rewind if io.respond_to?(:rewind)
      Base64.strict_encode64(io.read)
    ensure
      io.rewind if io.respond_to?(:rewind)
    end

    def rewound(image)
      if image.respond_to?(:tempfile)
        image.tempfile.rewind
      elsif image.respond_to?(:rewind)
        image.rewind
      end
    end

    def error(message)
      Analysis.new(success?: false, error_message: message)
    end

    def strip_code_fences(text)
      stripped = text.to_s.strip
      stripped = stripped.sub(/\A```(?:json)?\s*/i, "")
      stripped.sub(/```\s*\z/, "")
    end

    def normalize_macros(macros)
      normalized = {
        calories: convert_to_integer(macros[:calories]),
        protein_g: convert_to_integer(macros[:protein_g]),
        fats_g: convert_to_integer(macros[:fats_g]),
        carbs_g: convert_to_integer(macros[:carbs_g])
      }

      return nil if normalized.values.any?(&:nil?)

      normalized
    end

    def convert_to_integer(value)
      return nil if value.nil?
      Integer(value)
    rescue ArgumentError, TypeError
      # Try parsing as a float and round. If that also fails, return nil.
      begin
        Float(value).round
      rescue ArgumentError, TypeError
        nil
      end
    end
  end
end
