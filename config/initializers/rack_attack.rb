class Rack::Attack
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    #Rack::Attack.throttle "logins/ip", limit: 20, period: 1 do |req|
    #  req.post? && req.path == "/api-docs" && req.ip
    #end

    throttle('api/ip', limit: 3, period: 10) do |req|
      if req.path.match?(/^\/api\/v1\/companies$/i) && req.get?
        req.ip
      elsif  req.path.match?(/^\/api\/v1\/companies\/\d+$/) && req.patch?
        req.ip
      elsif  req.path.match?(/^\/api\/v1\/companies\/\d+$/) && req.delete?
        req.ip
      end
    end

  end
