require "rails_helper"

RSpec.describe "Admin page widgets", type: :system, js: true do
  before { driven_by :selenium_chrome_headless_xl }

  let(:current_user) { create(:user, :super_admin) }

  let!(:gallery)      { create(:gallery,      name: "Spring Gallery") }
  let!(:location)     { create(:location,     name: "Main Hall") }
  let!(:inquiry_form) { create(:inquiry_form, name: "Contact Us", redirect_path: "/") }
  let!(:qr_code)      { create(:qr_code,      name: "Entrance QR") }
  let!(:listing)      { create(:listing,      name: "Oak Chair", published: true) }
  let!(:page_record)  { create(:page) }

  before { sign_in_as(current_user) }

  # Maps the human-readable type label used in the form select to the
  # data-widget-type-fields value used on the FK selector container.
  WIDGET_TYPE_CLASS = {
    "Gallery"      => "GalleryWidget",
    "Location"     => "LocationWidget",
    "Schedule"     => "ScheduleWidget",
    "Contact Form" => "ContactFormWidget",
    "QR Code"      => "QrCodeWidget",
    "Listing"      => "ListingWidget"
  }.freeze

  def add_widget(type:, resource_name:)
    existing_count = all("[data-widget-row]").count
    click_button "Add Widget"

    # Wait for JS to append the new row before interacting with it.
    expect(page).to have_selector("[data-widget-row]", count: existing_count + 1)
    row = all("[data-widget-row]").last

    within(row) do
      find("[data-widget-type-select]").select(type)
      # Wait for JS to reveal the FK selector for this type, then pick the record.
      find("[data-widget-type-fields='#{WIDGET_TYPE_CLASS[type]}'] select").select(resource_name)
    end
  end

  it "adds every widget type and persists them on save" do
    visit edit_admin_page_path(page_record)

    add_widget(type: "Gallery",      resource_name: gallery.name)
    add_widget(type: "Location",     resource_name: location.name)
    add_widget(type: "Schedule",     resource_name: location.name)
    add_widget(type: "Contact Form", resource_name: inquiry_form.name)
    add_widget(type: "QR Code",      resource_name: qr_code.name)
    add_widget(type: "Listing",      resource_name: listing.name)

    click_button "Update Page"

    expect(page).to have_text("Page was successfully updated.")

    widgets = page_record.reload.widgets
    expect(widgets.count).to eq(6)
    expect(widgets.map(&:type)).to match_array(%w[
      GalleryWidget LocationWidget ScheduleWidget
      ContactFormWidget QrCodeWidget ListingWidget
    ])
    expect(widgets.find { |w| w.is_a?(GalleryWidget) }.gallery).to      eq(gallery)
    expect(widgets.find { |w| w.is_a?(LocationWidget) }.location).to    eq(location)
    expect(widgets.find { |w| w.is_a?(ScheduleWidget) }.location).to    eq(location)
    expect(widgets.find { |w| w.is_a?(ContactFormWidget) }.inquiry_form).to eq(inquiry_form)
    expect(widgets.find { |w| w.is_a?(QrCodeWidget) }.qr_code).to       eq(qr_code)
    expect(widgets.find { |w| w.is_a?(ListingWidget) }.listing).to       eq(listing)
  end
end
