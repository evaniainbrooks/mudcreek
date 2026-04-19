class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    page = Current.tenant.homepage_page
    return redirect_to(listings_path, status: :moved_permanently) unless page&.published?

    @page = page
    @children = @page.children.published.order(:position, :id)
                     .with_attached_left_column_image
                     .with_attached_right_column_image
                     .with_attached_hero_image
    @active_child = @children.find { |c| c.slug == params[:tab] } || @children.first
    @widgets = @page.widgets.to_a
    preload_widget_associations(@widgets)
    @child_widgets = @active_child ? @active_child.widgets.to_a : []
    preload_widget_associations(@child_widgets)

    render "pages/show"
  end

  private

  def preload_widget_associations(widgets)
    preload(widgets.grep(GalleryWidget),     :gallery)
    preload(widgets.grep(LocationWidget) + widgets.grep(ScheduleWidget), :location)
    preload(widgets.grep(ContactFormWidget), :inquiry_form)
    preload(widgets.grep(QrCodeWidget),      :qr_code)
    preload(widgets.grep(ListingWidget),
      listing: [ :gallery, :properties, :categories, :rental_rate_plans,
                 { lot: :listing_placeholder_attachment } ])
  end

  def preload(records, associations)
    return if records.empty?

    ActiveRecord::Associations::Preloader.new(records: records, associations: associations).call
  end
end
