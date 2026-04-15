class ProvisionCloudflareTurnstileJob < ApplicationJob
  queue_as :default

  def perform(tenant_id)
    tenant = Tenant.find(tenant_id)
    Current.tenant = tenant

    return unless tenant.custom_domain.present?

    tenant.with_advisory_lock("cloudflare_turnstiles") do
      widget_data = locate_or_provision(tenant)
      return unless widget_data

      record = Cloudflare::TurnstileWidget.find_or_initialize_by(tenant: tenant)
      record.update!(external_id: widget_data["sitekey"], api_response: widget_data)

      broadcast(tenant, record)
    end
  end

  private

  def locate_or_provision(tenant)
    client = CloudflareClient.new
    all_widgets = fetch_all_widgets(client)

    # Idempotent: domain already registered to an existing widget
    existing = all_widgets.find { |w| Array(w["domains"]).include?(tenant.custom_domain) }
    return existing if existing

    # Add domain to a widget that still has capacity
    candidate = all_widgets.find { |w| Array(w["domains"]).length < 10 }

    if candidate
      result = client.update_widget(
        candidate["sitekey"],
        name: candidate["name"],
        domains: Array(candidate["domains"]) + [ tenant.custom_domain ],
        mode: candidate["mode"]
      )
      return result[:widget] if result[:success]
    end

    # No suitable widget — create one
    result = client.create_widget(
      name: "#{tenant.name} Turnstile",
      domains: [ tenant.custom_domain ],
      mode: "managed"
    )
    result[:success] ? result[:widget] : nil
  end

  def fetch_all_widgets(client)
    widgets = []
    page = 1

    loop do
      result = client.list_widgets(page: page, per_page: 25)
      break unless result[:success]

      widgets.concat(result[:widgets])
      break if result[:widgets].length < 25

      page += 1
    end

    widgets
  end

  def broadcast(tenant, widget)
    Turbo::StreamsChannel.broadcast_replace_to(
      "cloudflare_turnstile_#{tenant.id}",
      target: "turnstile-widget-status",
      partial: "admin/turnstiles/widget_status",
      locals: { widget: }
    )
  end
end
