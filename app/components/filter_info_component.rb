class FilterInfoComponent < ViewComponent::Base
  def initialize(count:, total:, label:, clear_url: nil)
    @count = count
    @total = total
    @label = label
    @clear_url = clear_url
  end

  def render?
    @total > 0
  end

  def filtered?
    @count != @total
  end
end
