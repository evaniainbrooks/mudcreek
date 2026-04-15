class Cloudflare::TurnstileWidget < ApplicationRecord
  include MultiTenant

  validates :tenant_id, uniqueness: true
  validates :external_id, presence: true, uniqueness: true

  def sitekey   = api_response["sitekey"]
  def secret    = api_response["secret"]
  def widget_name = api_response["name"]
  def domains   = Array(api_response["domains"])
  def mode      = api_response["mode"]
end
