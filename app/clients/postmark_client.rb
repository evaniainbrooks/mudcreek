class PostmarkClient
  def initialize(account_token = Rails.application.credentials.postmark.account_token)
    @client = Postmark::AccountApiClient.new(account_token)
  end

  # Returns a normalized domain hash, or nil if not found
  def find_domain_by_name(name)
    existing = @client.get_domains.find { |d| d[:name] == name }
    return nil unless existing

    @client.get_domain(existing[:id]).stringify_keys
  rescue => e
    Rails.logger.error("PostmarkClient#find_domain_by_name failed: #{e.message}")
    nil
  end

  # Returns { success:, domain: {...}, error: }
  def create_domain(name)
    result = @client.create_domain(name: name).stringify_keys
    { success: true, domain: result, error: nil }
  rescue => e
    { success: false, domain: nil, error: e.message }
  end

  # Triggers DKIM + return-path verification, then fetches updated domain state.
  # Returns { success:, domain: {...}, error: }
  def verify_domain(id)
    @client.verify_domain_dkim(id)
    @client.verify_domain_return_path(id)
    domain = @client.get_domain(id).stringify_keys
    { success: domain["dkim_verified"] == true, domain: domain, error: nil }
  rescue => e
    { success: false, domain: nil, error: e.message }
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
