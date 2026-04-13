class PagesController < ApplicationController
  allow_unauthenticated_access

  def show
    @page = Page.published.find_by!(slug: params[:slug])
    @children = @page.children.published.order(:position, :id)
    @active_child = @children.find { |c| c.slug == params[:tab] } || @children.first
    @inquiry_form = @page.inquiry_form
    @inquiry = Inquiry.new if @inquiry_form
  end
end
