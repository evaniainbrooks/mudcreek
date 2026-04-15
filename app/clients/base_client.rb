require "net/http"

class BaseClient
  def get(uri)
    request(Net::HTTP::Get.new(uri), uri)
  end

  def post(uri, body = nil)
    req = Net::HTTP::Post.new(uri)
    req.body = body.to_json if body
    req["Content-Type"] = "application/json"
    request(req, uri)
  end

  def put(uri, body = nil)
    req = Net::HTTP::Put.new(uri)
    req.body = body.to_json if body
    req["Content-Type"] = "application/json"
    request(req, uri)
  end

  def delete(uri)
    request(Net::HTTP::Delete.new(uri), uri)
  end

  private

  def request(req, uri)
    apply_auth(req)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") { |h| h.request(req) }
  end

  def apply_auth(req)
    # Override in subclasses to set Authorization header
  end
end
