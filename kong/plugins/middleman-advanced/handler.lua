local BasePlugin = require "kong.plugins.base_plugin"
local access = require "kong.plugins.middleman-advanced.access"
local kong_tls = require "resty.kong.tls"

local MiddlemanAdvancedHandler = BasePlugin:extend()

MiddlemanAdvancedHandler.PRIORITY = 900

function MiddlemanAdvancedHandler:new()
  MiddlemanAdvancedHandler.super.new(self, "middleman-advanced")
end

function MiddlemanAdvancedHandler:access(conf)
  MiddlemanAdvancedHandler.super.access(self)
  access.execute(conf)
end

function MiddlemanAdvancedHandler:init_worker()

  local orig_ssl_certificate = Kong.ssl_certificate
  Kong.ssl_certificate = function()
    orig_ssl_certificate()
    kong.log.debug("enabled, will request certificate from client")

    local res, err = kong_tls.request_client_certificate()
    if not res then
      kong.log.err("unable to request client to present its certificate: ", err)
    end

    -- disable session resumption to prevent inability to access client
    -- certificate
    -- see https://github.com/Kong/lua-kong-nginx-module#restykongtlsget_full_client_certificate_chain
    res, err = kong_tls.disable_session_reuse()
    if not res then
      kong.log.err("unable to disable session reuse for client certificate: ",
                   err)
    end
  end

  MiddlemanAdvancedHandler.super.init_worker(self)
end

return MiddlemanAdvancedHandler
