class PagesController < ApplicationController
  allow_unauthenticated_access

  def show
    @page = Page.published.find_by!(slug: params[:slug])
    @children = @page.children.published.order(:position, :id)
                     .with_attached_left_column_image
                     .with_attached_right_column_image
                     .with_attached_hero_image
    @active_child = @children.find { |c| c.slug == params[:tab] } || @children.first
    @widgets = @page.widgets.includes(:gallery, :location, :inquiry_form, :qr_code, listing: [ :gallery, :properties, :categories, :rental_rate_plans, { lot: :listing_placeholder_attachment } ])
  end
end
