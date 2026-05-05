import { application } from "./application"
import AddCardController from "./add_card_controller"
import AsyncContentController from "./async_content_controller"
import DirectUploadController from "./direct_upload_controller"
import BidIncrementScheduleController from "./bid_increment_schedule_controller"
import AddressController from "./address_controller"
import BidButtonController from "./bid_button_controller"
import CountdownController from "./countdown_controller"
import CartController from "./cart_controller"
import BulkSelectController from "./bulk_select_controller"
import BookingCalendarController from "./booking_calendar_controller"
import HelloController from "./hello_controller"
import ImageZoomController from "./image_zoom_controller"
import InfiniteScrollController from "./infinite_scroll_controller"
import InlineEditController from "./inline_edit_controller"
import ListingCarouselController from "./listing_carousel_controller"
import ListingOptionController from "./listing_option_controller"
import ListingVariantGalleryController from "./listing_variant_gallery_controller"
import ListingPropertyController from "./listing_property_controller"
import ListingTypeController from "./listing_type_controller"
import RentalAvailabilityController from "./rental_availability_controller"
import RentalModalController from "./rental_modal_controller"
import SocialMediaAccountController from "./social_media_account_controller"
import ShareController from "./share_controller"
import SortableController from "./sortable_controller"
import SquarePaymentController from "./square_payment_controller"
import ViewToggleController from "./view_toggle_controller"
import IconPickerController from "./icon_picker_controller"
import ClockController from "./clock_controller"
import NavbarController from "./navbar_controller"
import QrImageController from "./qr_image_controller"
import SlideshowController from "./slideshow_controller"
import LedgerEntryController from "./ledger_entry_controller"
import PageFormController from "./page_form_controller"
import PageWidgetsController from "./page_widgets_controller"
import RruleBuilderController from "./rrule_builder_controller"
import ScheduleTableController from "./schedule_table_controller"

application.register("add-card", AddCardController)
application.register("async-content", AsyncContentController)
application.register("direct-upload", DirectUploadController)
application.register("address", AddressController)
application.register("bid-increment-schedule", BidIncrementScheduleController)
application.register("bid-button", BidButtonController)
application.register("countdown", CountdownController)
application.register("cart", CartController)
application.register("bulk-select", BulkSelectController)
application.register("booking-calendar", BookingCalendarController)
application.register("hello", HelloController)
application.register("image-zoom", ImageZoomController)
application.register("infinite-scroll", InfiniteScrollController)
application.register("inline-edit", InlineEditController)
application.register("listing-carousel", ListingCarouselController)
application.register("listing-option", ListingOptionController)
application.register("listing-variant-gallery", ListingVariantGalleryController)
application.register("listing-property", ListingPropertyController)
application.register("listing-type", ListingTypeController)
application.register("rental-availability", RentalAvailabilityController)
application.register("rental-modal", RentalModalController)
application.register("social-media-account", SocialMediaAccountController)
application.register("share", ShareController)
application.register("sortable", SortableController)
application.register("square-payment", SquarePaymentController)
application.register("view-toggle", ViewToggleController)
application.register("icon-picker", IconPickerController)
application.register("clock", ClockController)
application.register("navbar", NavbarController)
application.register("qr-image", QrImageController)
application.register("slideshow", SlideshowController)
application.register("ledger-entry", LedgerEntryController)
application.register("page-form", PageFormController)
application.register("page-widgets", PageWidgetsController)
application.register("rrule-builder", RruleBuilderController)
application.register("schedule-table", ScheduleTableController)
