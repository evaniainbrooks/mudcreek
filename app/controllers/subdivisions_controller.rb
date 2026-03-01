class SubdivisionsController < ApplicationController
  def index
    country = ISO3166::Country[params[:country_code]]
    names = country&.subdivisions&.values&.map(&:name)&.compact&.sort || []
    render json: names
  end
end
