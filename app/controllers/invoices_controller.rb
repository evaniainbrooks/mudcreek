class InvoicesController < ApplicationController
  before_action :set_invoice, only: [:show, :pay]

  def show
  end

  def pay
    if @invoice.paid?
      redirect_to edit_profile_path, alert: "That invoice has already been paid."
      return
    end

    Current.user.cart_items.destroy_all
    session.delete(:delivery_method_id)
    session.delete(:discount_code_id)

    @invoice.invoice_items.includes(:listing).each do |item|
      next unless item.listing.present?
      Current.user.cart_items.create!(listing: item.listing, invoice_item: item)
    end

    redirect_to cart_path, notice: "Your cart has been loaded with your invoice items. Complete checkout to pay your invoice."
  end

  private

  def set_invoice
    @invoice = Current.user.invoices.find_by!(number: params[:number])
  end
end
