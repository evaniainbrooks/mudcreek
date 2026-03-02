module CountriesHelper
  def all_countries = ISO3166::Country.all.sort_by(&:common_name).map { |c| [c.common_name, c.alpha2] }
end
