
local cjson = require "cjson"
local cjson2 = cjson.new()

local http = require "resty.http"
local httpc = http.new()

local url = require "net.url"

-- get the json from the request body
local body = ngx.req.read_body()
if not body then
  body = ngx.req.get_body_data()
end

local body_data = cjson.decode(body)

-- search for hrefs
function href_find (tbl, path, found)
  if not found then
    found = {}
  end
  if not path then
    path = '/'
  end
  for k,v in pairs(tbl) do
    if k == "href" then
      found[path] = v
    end
    if type(v) == "table" then
      found = href_find(v, path .. '/' .. k, found)
    end
  end
  return found
end
local hrefs = href_find(body_data, "/", nil)

-- connect to each href's server
local responses = {}
for data_path, href in pairs(hrefs) do
  -- parse our URL
  local href_details = url.parse(href)

  -- connect to the host
  httpc:set_timeout(500)
  httpc:connect(href_details["host"], 80)

  -- start our request
  local res, err = httpc:request{
    path = href_details["path"],
    headers = {
      ["Host"] = href_details["host"]
    },
  }
  -- keep track of our responses
  responses[href] = {}
  responses[href].res = res
  responses[href].err = err
end

-- go through the responses
for href, details in pairs(responses) do
  local res = details.res
  local err = details.err

  if not res then
    responses[href] = {error=err}

  else
    -- TODO, stream as available instead of starting from first req
    -- Now we can use the body_reader iterator, to stream the body
    -- according to our desired chunk size.
    local reader = res.body_reader

    responses[href] = ""
    repeat
      local chunk, err = reader(8192)
      if err then
        ngx.log(ngx.ERR, err)
        break
      end

      if chunk then
        responses[href] = responses[href] .. chunk
      end
    until not chunk

    -- local ok, err = httpc:set_keepalive()
    -- if not ok then
    --   ngx.say("failed to set keepalive: ", err)
    --   return
    -- end
  end
end

ngx.say(cjson.encode(responses))

ngx.exit(200)
