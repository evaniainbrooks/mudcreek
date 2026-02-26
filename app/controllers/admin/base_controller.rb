class Admin::BaseController < ApplicationController
  before_action { @admin = true }
end
