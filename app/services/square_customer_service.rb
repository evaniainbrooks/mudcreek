class SquareCustomerService
  Error = Class.new(StandardError)

  def initialize(user)
    @user = user
  end

  def find_or_create_customer!
    return @user.square_customer_id if @user.square_customer_id.present?

    response = SquareClient.client.customers.create(
      given_name: @user.first_name,
      family_name: @user.last_name,
      email_address: @user.email_address
    )
    @user.update_column(:square_customer_id, response.customer.id)
    @user.square_customer_id
  rescue Square::Errors::ResponseError => e
    raise Error, extract_error(e)
  end

  def create_card(source_id:)
    customer_id = find_or_create_customer!
    response = SquareClient.client.cards.create(
      idempotency_key: SecureRandom.uuid,
      source_id: source_id,
      card: { customer_id: customer_id, cardholder_name: @user.name }
    )
    response.card
  rescue Square::Errors::ResponseError => e
    raise Error, extract_error(e)
  end

  def list_cards
    return [] unless @user.square_customer_id.present?

    SquareClient.client.cards.list(customer_id: @user.square_customer_id).to_a
  rescue Square::Errors::ResponseError => e
    raise Error, extract_error(e)
  end

  def disable_card(card_id:)
    SquareClient.client.cards.disable(card_id: card_id)
    @user.update_column(:default_square_card_id, nil) if @user.default_square_card_id == card_id
  rescue Square::Errors::ResponseError => e
    raise Error, extract_error(e)
  end

  def set_default_card(card_id:)
    @user.update_column(:default_square_card_id, card_id)
  end

  private

  def extract_error(e)
    parsed = JSON.parse(e.message) rescue {}
    parsed.dig("errors", 0, "detail") || "Square API error."
  end
end
