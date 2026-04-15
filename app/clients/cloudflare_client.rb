class CloudflareClient < BaseClient
  BASE_URL = "https://api.cloudflare.com/client/v4"
  SITEVERIFY_URL = "https://challenges.cloudflare.com/turnstile/v1/siteverify"

  def initialize(
    api_token: Rails.application.credentials.dig(:cloudflare, :api_token),
    account_id: Rails.application.credentials.dig(:cloudflare, :account_id)
  )
    @api_token = api_token
    @account_id = account_id
  end

  # Returns { success:, widgets: [...], result_info: {...}, errors: [...] }
  def list_widgets(page: 1, per_page: 25, order: nil, direction: nil)
    params = { page:, per_page: }.tap do |p|
      p[:order] = order if order
      p[:direction] = direction if direction
    end
    uri = widgets_uri(query: params)
    body = JSON.parse(get(uri).body)
    { success: body["success"], widgets: body["result"] || [], result_info: body["result_info"], errors: body["errors"] || [] }
  rescue => e
    Rails.logger.error("CloudflareClient#list_widgets failed: #{e.message}")
    { success: false, widgets: [], result_info: nil, errors: [ e.message ] }
  end

  # Returns { success:, widget: {...}, errors: [...] }
  # mode: "managed" | "non-interactive" | "invisible"
  def create_widget(name:, domains:, mode: "managed", **options)
    uri = widgets_uri
    payload = { name:, domains:, mode: }.merge(options)
    body = JSON.parse(post(uri, payload).body)
    { success: body["success"], widget: body["result"], errors: body["errors"] || [] }
  rescue => e
    { success: false, widget: nil, errors: [ e.message ] }
  end

  # Returns { success:, widget: {...}, errors: [...] }
  def get_widget(sitekey)
    uri = widgets_uri(sitekey)
    body = JSON.parse(get(uri).body)
    { success: body["success"], widget: body["result"], errors: body["errors"] || [] }
  rescue => e
    { success: false, widget: nil, errors: [ e.message ] }
  end

  # Returns { success:, widget: {...}, errors: [...] }
  def update_widget(sitekey, name:, domains:, mode:, **options)
    uri = widgets_uri(sitekey)
    payload = { name:, domains:, mode: }.merge(options)
    body = JSON.parse(put(uri, payload).body)
    { success: body["success"], widget: body["result"], errors: body["errors"] || [] }
  rescue => e
    { success: false, widget: nil, errors: [ e.message ] }
  end

  # Returns { success:, errors: [...] }
  def delete_widget(sitekey)
    uri = widgets_uri(sitekey)
    body = JSON.parse(delete(uri).body)
    { success: body["success"], errors: body["errors"] || [] }
  rescue => e
    { success: false, errors: [ e.message ] }
  end

  # Rotates the secret key for a widget.
  # Returns { success:, widget: {...}, errors: [...] }
  def rotate_secret(sitekey, invalidate_immediately: false)
    uri = widgets_uri(sitekey, "rotate_secret")
    body = JSON.parse(post(uri, { invalidate_immediately: }).body)
    { success: body["success"], widget: body["result"], errors: body["errors"] || [] }
  rescue => e
    { success: false, widget: nil, errors: [ e.message ] }
  end

  # Verifies a Turnstile challenge token against Cloudflare's siteverify endpoint.
  # Does not use the account API credentials — the widget secret authenticates the request.
  # Returns { success: bool }
  def verify_token(secret:, token:, remote_ip: nil)
    uri = URI(SITEVERIFY_URL)
    body = { secret: secret, response: token }
    body[:remoteip] = remote_ip if remote_ip.present?

    req = Net::HTTP::Post.new(uri)
    req["Content-Type"] = "application/json"
    req.body = body.to_json

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |h| h.request(req) }
    parsed = JSON.parse(response.body)
    { success: parsed["success"] == true }
  rescue => e
    Rails.logger.error("CloudflareClient#verify_token failed: #{e.message}")
    { success: false }
  end

  private

  def widgets_uri(*parts, query: nil)
    path = [ BASE_URL, "accounts", @account_id, "challenges", "widgets", *parts ].join("/")
    uri = URI(path)
    uri.query = URI.encode_www_form(query) if query
    uri
  end

  def apply_auth(req)
    req["Authorization"] = "Bearer #{@api_token}"
  end
end
