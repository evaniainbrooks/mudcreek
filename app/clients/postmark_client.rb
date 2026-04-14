class PostmarkClient
  def initialize(account_token = Rails.application.credentials.postmark.account_token)
    @client = Postmark::AccountApiClient.new(account_token)
  end

  # Returns an array of normalized signature hashes
  def list_signatures
    @client.get_senders.map { |s| normalize(s) }
  rescue => e
    Rails.logger.error("PostmarkClient#list_signatures failed: #{e.message}")
    []
  end

  # Returns { success:, signature: { id:, name:, email_address:, confirmed:, ... }, error: }
  def create_signature(from_email:, name:)
    result = @client.create_sender(from_email: from_email, name: name)
    { success: true, signature: normalize(result), error: nil }
  rescue => e
    { success: false, signature: nil, error: e.message }
  end

  # Returns { success:, error: }
  def delete_signature(id)
    @client.delete_sender(id)
    { success: true, error: nil }
  rescue => e
    { success: false, error: e.message }
  end

  # Returns { success:, error: }
  def resend_confirmation(id)
    @client.resend_sender_confirmation(id)
    { success: true, error: nil }
  rescue => e
    { success: false, error: e.message }
  end

  private

  def normalize(response)
    {
      id: response[:id],
      name: response[:name],
      email_address: response[:email_address],
      confirmed: response[:confirmed],
      dkim_verified: response[:dkim_verified],
      spf_verified: response[:spf_verified],
      return_path_domain_verified: response[:return_path_domain_verified]
    }
  end
end
