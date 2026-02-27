import { application } from "./application"
import HelloController from "./hello_controller"
import ImageZoomController from "./image_zoom_controller"
import InfiniteScrollController from "./infinite_scroll_controller"
import ViewToggleController from "./view_toggle_controller"

application.register("hello", HelloController)
application.register("image-zoom", ImageZoomController)
application.register("infinite-scroll", InfiniteScrollController)
application.register("view-toggle", ViewToggleController)
