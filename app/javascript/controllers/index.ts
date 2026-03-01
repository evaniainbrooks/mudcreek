import { application } from "./application"
import BookingCalendarController from "./booking_calendar_controller"
import HelloController from "./hello_controller"
import ImageZoomController from "./image_zoom_controller"
import InfiniteScrollController from "./infinite_scroll_controller"
import InlineEditController from "./inline_edit_controller"
import ListingCarouselController from "./listing_carousel_controller"
import ListingTypeController from "./listing_type_controller"
import RentalModalController from "./rental_modal_controller"
import SortableController from "./sortable_controller"
import ViewToggleController from "./view_toggle_controller"

application.register("booking-calendar", BookingCalendarController)
application.register("hello", HelloController)
application.register("image-zoom", ImageZoomController)
application.register("infinite-scroll", InfiniteScrollController)
application.register("inline-edit", InlineEditController)
application.register("listing-carousel", ListingCarouselController)
application.register("listing-type", ListingTypeController)
application.register("rental-modal", RentalModalController)
application.register("sortable", SortableController)
application.register("view-toggle", ViewToggleController)
