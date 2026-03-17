class Profiles::InvoicesController < Profiles::BaseController
  def show
    @invoices = Current.user.invoices.includes(:auction, offer: :listing).order(created_at: :desc)
  end
end
