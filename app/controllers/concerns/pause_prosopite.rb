module PauseProsopite
  extend ActiveSupport::Concern

  included do
    around_action :pause_prosopite, if: -> { action_name == "destroy" }
  end

  private

  def pause_prosopite(&block)
    Prosopite.pause(&block)
  end
end
