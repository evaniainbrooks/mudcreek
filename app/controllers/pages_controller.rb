class PagesController < ApplicationController
  allow_unauthenticated_access

  def show
    @page = Page.published.find_by!(slug: params[:slug])
  end
end
