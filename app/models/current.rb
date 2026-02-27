class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :tenant
  delegate :user, to: :session, allow_nil: true
end
