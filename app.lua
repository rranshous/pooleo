
local cjson = require "cjson"
local cjson2 = cjson.new()

local http = require "resty.http"
local httpc = http.new()

local url = require "net.url"

-- get the json from the request body
local body = ngx.req.read_body()
if not body then
  ngx.log(ngx.DEBUG, "getting body from cache")
  body = ngx.req.get_body_data()
end
ngx.log(ngx.INFO, "BODY: ", body)

local body_data = cjson.decode(body)

-- pull the href from the bodies data { "href" : "" }
local href = body_data["href"]
ngx.log(ngx.INFO, "HREF: ", href)

-- parse our URL
local href_details = url.parse(href)
local host = href_details.host
local path = href_details.path
ngx.log(ngx.INFO, "HOST: ", host)
ngx.log(ngx.INFO, "PATH: ", path)

-- connect to the host
httpc:set_timeout(500)
httpc:connect(href_details["host"], 80)

-- make our request out
local res, err = httpc:request{
  path = href_details["path"],
  headers = {
    ["Host"] = host
  },
}

if not res then
  ngx.say("failed to request: ", err)
  return
end

-- Now we can use the body_reader iterator, to stream the body according to our desired chunk size.
local reader = res.body_reader

repeat
  local chunk, err = reader(8192)
  if err then
    ngx.log(ngx.ERR, err)
    break
  end

  if chunk then
    ngx.say(chunk)
  end
until not chunk

local ok, err = httpc:set_keepalive()
if not ok then
  ngx.say("failed to set keepalive: ", err)
  return
end


-- ngx.say('Hello World!')
-- ngx.exit(200)
