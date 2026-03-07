class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  around_perform :scan_for_n_plus_one, if: -> { Rails.env.local? }

  private

  def scan_for_n_plus_one
    Prosopite.scan
    yield
  ensure
    Prosopite.finish
  end
end
