FactoryBot.define do
  factory :cloudflare_turnstile_widget, class: "Cloudflare::TurnstileWidget" do
    sequence(:external_id) { |n| "widget_#{n}" }
    api_response           { { "sitekey" => "0x4AAAA", "secret" => "0xSECRET", "name" => "Test Widget", "domains" => [], "mode" => "managed" } }
  end
end
