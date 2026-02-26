import { application } from "./application"
import HelloController from "./hello_controller"
import InfiniteScrollController from "./infinite_scroll_controller"

application.register("hello", HelloController)
application.register("infinite-scroll", InfiniteScrollController)
