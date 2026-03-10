class BidListener
  CHANNEL = "bid_events"
  TIMEOUT = 5  # seconds; nil = block indefinitely

  def self.start
    new.run
  end

  def run
    with_connection do |conn|
      conn.exec("LISTEN #{CHANNEL}")
      Rails.logger.info "[BidListener] Listening on '#{CHANNEL}'"

      loop do
        conn.wait_for_notify(TIMEOUT) do |_channel, _pid, payload|
          handle(payload)
        end
      end
    end
  end

  private

  def handle(payload)
    data = JSON.parse(payload)
    Rails.logger.info "[BidListener] event bid_id=#{data['bid_id']} " \
                      "listing_id=#{data['auction_listing_id']} " \
                      "amount_cents=#{data['amount_cents']} state=#{data['state']}"

    on_bid_event(data)
  rescue => e
    Rails.logger.error "[BidListener] Error handling payload: #{e.message}"
  end

  def on_bid_event(data)
    BidBroadcastService.call(data)
  end

  def with_connection
    cfg = ActiveRecord::Base.connection_db_config.configuration_hash
    conn = PG.connect(
      host:     cfg[:host],
      port:     cfg[:port],
      dbname:   cfg[:database],
      user:     cfg[:username],
      password: cfg[:password]
    )
    yield conn
  ensure
    conn&.finish
  end
end
