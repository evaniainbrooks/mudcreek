class CategoriesController < ApplicationController
  allow_unauthenticated_access only: [:index]

  def index
    @categories = Listings::Category.includes(hero_image_attachment: :blob).order(:name)
  end
end
