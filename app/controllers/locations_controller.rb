class LocationsController < ApplicationController
  include LocationFeatureGated

  allow_unauthenticated_access
  layout "showroom"
end
