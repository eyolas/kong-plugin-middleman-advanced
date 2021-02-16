local JSON = require "kong.plugins.middleman-advanced.json"
local PAYLOAD = require "kong.plugins.middleman-advanced.payload"
local url = require "socket.url"

local kong = kong
local kong_response = kong.response

local ngx_re_match = ngx.re.match
local ngx_re_find = ngx.re.find

local HTTP = "http"
local HTTPS = "https"

local _M = {}

local function parse_url(host_url)
  local parsed_url = url.parse(host_url)
  if not parsed_url.port then
    if parsed_url.scheme == HTTP then
      parsed_url.port = 80
    elseif parsed_url.scheme == HTTPS then
      parsed_url.port = 443
    end
  end
  if not parsed_url.path then parsed_url.path = "/" end
  return parsed_url
end

local function send(conf)
  local name = "[middleman-advanced] "
  local ok, err
  local parsed_url = parse_url(conf.url)
  local host = parsed_url.host
  local port = tonumber(parsed_url.port)
  local payload = PAYLOAD.compose_payload(parsed_url, conf, nil)

  local sock = ngx.socket.tcp()
  sock:settimeout(conf.timeout)

  ok, err = sock:connect(host, port)
  if not ok then
    kong.log.err(name .. "failed to connect to " .. host .. ":" ..
                     tostring(port) .. ": ", err)
    return false, nil, nil
  end

  if parsed_url.scheme == HTTPS then
    local _, err = sock:sslhandshake(true, host, false)
    if err then
      kong.log.err(name .. "failed to do SSL handshake with " .. host .. ":" ..
                       tostring(port) .. ": ", err)
    end
  end

  ok, err = sock:send(payload)
  if not ok then
    kong.log.err(name .. "failed to send data to " .. host .. ":" ..
                     tostring(port) .. ": ", err)
  end

  local line, err = sock:receive("*l")

  if err then
    kong.log.err(
        name .. "failed to read response status from " .. host .. ":" ..
            tostring(port) .. ": ", err)
    return false, nil, nil
  end

  local status_code = tonumber(string.match(line, "%s(%d%d%d)%s"))
  local headers = {}

  repeat
    line, err = sock:receive("*l")
    if err then
      kong.log.err(name .. "failed to read header " .. host .. ":" ..
                       tostring(port) .. ": ", err)
      return false, nil, nil
    end

    local pair = ngx_re_match(line, "(.*):\\s*(.*)", "jo")

    if pair then headers[string.lower(pair[1])] = pair[2] end
  until ngx_re_find(line, "^\\s*$", "jo")

  local body, err = sock:receive(tonumber(headers['content-length']))
  if err then
    kong.log.err(
        name .. "failed to read body " .. host .. ":" .. tostring(port) .. ": ",
        err)
    return false, nil, nil
  end

  ok, err = sock:setkeepalive(conf.keepalive)
  if not ok then
    kong.log.err(name .. "failed to keepalive to " .. host .. ":" ..
                     tostring(port) .. ": ", err)
    return false, nil, nil
  end

  if status_code > 299 then
    if err then
      kong.log.err(name .. "failed to read response from " .. host .. ":" ..
                       tostring(port) .. ": ", err)
    end

    local response_body
    if conf.response == "table" then
      response_body = JSON.decode(string.match(body, "%b{}"))
    else
      response_body = string.match(body, "%b{}")
    end

    return true, status_code, response_body
  end
end

function _M.execute(conf)
  if conf.services ~= nil then
    for i, config in pairs(conf.services) do
      local b, code, body = send(config)
      if b then return kong_response.exit(code, body) end
    end
  end
end

return _M
