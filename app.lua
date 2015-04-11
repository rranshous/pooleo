
local cjson = require "cjson"
local cjson2 = cjson.new()
local cjson_safe = require "cjson.safe"

local http = require "resty.http"
local httpc = http.new()

-- get the json from the request body
local body = ngx.req.get_body_data()
ngx.log("BODY: ", body)
local body_data = cjson.decode(body)

-- pull the href from the bodies data { "href" : "" }
local href = body_data["href"]
ngx.log("HREF: ", href)

-- parse our URL
-- local host = url:match("[%w%.]*%.(%w+%.%w+)")
local href_details = url.parse(href)
local host = href_details["host"]
local path = href_details["path"]
ngx.log("HOST: ", host)
ngx.log("PATH: ", path)

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
