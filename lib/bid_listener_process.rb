class BidListenerProcess
  def self.run
    new.start
  end

  def start
    trap("TERM") { @stop = true }
    trap("INT")  { @stop = true }

    Rails.logger.info "[BidListenerProcess] Starting"

    until @stop
      begin
        BidListener.start
      rescue => e
        Rails.logger.error "[BidListenerProcess] Restarting after error: #{e.message}"
        sleep 2
        retry unless @stop
      end
    end

    Rails.logger.info "[BidListenerProcess] Stopped"
  end
end
