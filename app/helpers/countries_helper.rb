module CountriesHelper
  def all_countries = ISO3166::Country.all.sort_by(&:common_name).map { |c| [c.common_name, c.alpha2] }

  def country_name(alpha2_code)
    ISO3166::Country[alpha2_code]&.common_name.presence || alpha2_code
  end

  def country_subdivisions(alpha2_code)
    ISO3166::Country[alpha2_code]&.subdivisions&.values&.map(&:name)&.compact&.sort || []
  end
end
