require "net/http"
require "base64"

class ImprovmxService
  BASE_URL = "https://api.improvmx.com/v3"

  def initialize(api_key = Rails.application.credentials.improvmx.api_key)
    @api_key = api_key
  end

  # Returns a hash: { success:, records: [...], errors: [...] }
  def check_domain(domain)
    uri = URI("#{BASE_URL}/domains/#{domain}/check")
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Basic #{Base64.strict_encode64("api:#{@api_key}")}"

    resp = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |h| h.request(req) }
    body = JSON.parse(resp.body)

    { success: body["success"], records: body["records"] || [], errors: body["errors"] || [] }
  rescue => e
    { success: false, records: [], errors: [ e.message ] }
  end
end
