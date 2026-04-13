require "base64"

class ImprovmxClient < BaseClient
  BASE_URL = "https://api.improvmx.com/v3"

  def initialize(api_key = Rails.application.credentials.improvmx.api_key)
    @api_key = api_key
  end

  # Returns an array of alias hashes: [{ id:, alias:, forward: }, ...]
  def list_aliases(domain)
    uri = URI("#{BASE_URL}/domains/#{root_domain(domain)}/aliases")
    body = JSON.parse(get(uri).body)
    Array(body["aliases"])
  rescue => e
    Rails.logger.error("ImprovmxClient#list_aliases failed: #{e.message}")
    []
  end

  # Returns a hash: { success:, records: [...], errors: [...] }
  def check_domain(domain)
    uri = URI("#{BASE_URL}/domains/#{root_domain(domain)}/check")
    body = JSON.parse(get(uri).body)
    { success: body["success"], records: body["records"] || [], errors: body["errors"] || [] }
  rescue => e
    { success: false, records: [], errors: [ e.message ] }
  end

  private

  def root_domain(domain)
    PublicSuffix.domain(domain)
  end

  def apply_auth(req)
    req["Authorization"] = "Basic #{Base64.strict_encode64("api:#{@api_key}")}"
  end
end
