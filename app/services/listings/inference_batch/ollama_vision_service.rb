module Listings
  module InferenceBatch
    class OllamaVisionService
      Result = Data.define(:success, :data, :error)

      ENDPOINT = URI("http://localhost:11434/api/generate")
      MODEL = "llava"
      SYSTEM_PROMPT = <<~PROMPT.freeze
        You are a product listing assistant for an auction house. Analyze the provided image and
        return a JSON object describing the item for a product listing. Use the available categories
        list to match appropriate categories. Return ONLY valid JSON with no extra text.

        Expected JSON shape:
        {
          "name": "short descriptive title",
          "description": "plain text, 2-4 sentences describing the item",
          "categories": ["category name matching the available list"],
          "properties": [{"name": "property name", "value": "property value"}],
          "price_cents": 0,
          "pricing_type": "firm or negotiable"
        }
      PROMPT

      def self.call(image_data, content_type, category_names)
        new(image_data, content_type, category_names).call
      end

      def initialize(image_data, content_type, category_names)
        @image_data = image_data
        @content_type = content_type
        @category_names = category_names
      end

      def call
        system_prompt = build_system_prompt
        base64_image = Base64.strict_encode64(@image_data)

        body = {
          model: MODEL,
          stream: false,
          format: "json",
          system: system_prompt,
          prompt: "Analyze this image. Return only the JSON object.",
          images: [ base64_image ]
        }.to_json

        response = Net::HTTP.start(ENDPOINT.hostname, ENDPOINT.port, read_timeout: 120) do |http|
          request = Net::HTTP::Post.new(ENDPOINT.path)
          request["Content-Type"] = "application/json"
          request.body = body
          http.request(request)
        end

        raise "Ollama returned #{response.code}" unless response.is_a?(Net::HTTPSuccess)

        outer = JSON.parse(response.body)
        data = JSON.parse(outer["response"])

        Result.new(success: true, data: data, error: nil)
      rescue => e
        Result.new(success: false, data: nil, error: e.message)
      end

      private

      def build_system_prompt
        if @category_names.any?
          "#{SYSTEM_PROMPT}\nAvailable categories: #{@category_names.join(', ')}"
        else
          SYSTEM_PROMPT
        end
      end
    end
  end
end
