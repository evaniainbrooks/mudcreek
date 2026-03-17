class Profiles::PaymentMethodsController < Profiles::BaseController
  def show
    @cards = SquareCustomerService.new(Current.user).list_cards rescue []
    @default_card_id = Current.user.default_square_card_id
  end
end
