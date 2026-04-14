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

  # Returns a hash: { success:, error: }
  def delete_alias(domain, alias_name)
    uri = URI("#{BASE_URL}/domains/#{root_domain(domain)}/aliases/#{alias_name}")
    body = JSON.parse(delete(uri).body)
    { success: body["success"], error: body["error"] }
  rescue => e
    { success: false, error: e.message }
  end

  # Returns a hash: { success:, alias: { id:, alias:, forward: }, error: }
  def create_alias(domain, alias_name, forward)
    uri = URI("#{BASE_URL}/domains/#{root_domain(domain)}/aliases")
    body = JSON.parse(post(uri, { alias: alias_name, forward: forward }).body)
    { success: body["success"], alias: body["alias"], error: body["error"] }
  rescue => e
    { success: false, alias: nil, error: e.message }
  end

  # Returns a hash: { success:, domain: {...} }
  def get_domain(domain)
    uri = URI("#{BASE_URL}/domains/#{root_domain(domain)}")
    body = JSON.parse(get(uri).body)
    { success: body["success"], domain: body["domain"] }
  rescue => e
    { success: false, domain: nil }
  end

  # Returns a hash: { success:, domain: {...}, error: }
  def create_domain(domain)
    uri = URI("#{BASE_URL}/domains")
    body = JSON.parse(post(uri, { domain: root_domain(domain) }).body)
    { success: body["success"], domain: body["domain"], error: body["error"] }
  rescue => e
    { success: false, domain: nil, error: e.message }
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
