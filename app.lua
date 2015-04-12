
local cjson = require "cjson"
local cjson2 = cjson.new()

local http = require "resty.http"
-- local httpc = http.new()

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

-- make http connections
local responses = {}
for data_path, href in pairs(hrefs) do
  -- parse our URL
  local href_details = url.parse(href)

  -- connect to the host
  local httpc = http.new()
  httpc:set_timeout(5000)
  ngx.log(ngx.ERR, "HOST: ",href_details.host)
  httpc:connect(href_details.host, href_details.port or 80)
  -- start our request
  local params = {
    path = href_details.path,
    headers = {
      ["Host"] = href_details.host
    },
  }
  local res, err = httpc:send_request(params)

  -- keep track of our responses
  responses[href] = {}
  responses[href].httpc = httpc
  responses[href].res = res
  responses[href].err = err
  responses[href].params = params
end

-- fill out responses
for href, details in pairs(responses) do
  local res = details.res
  local err = details.err
  local httpc = details.httpc
  local params = details.params

  if not res then
    responses[href] = {error={message=err}}

  else
    -- start reading the response
    res = httpc:read_response(params)
    if not res then
      responses[href] = {error={message=err}}

    elseif res.status ~= 200 then
      responses[href] = {error={status=res.status,message="bad response"}}

    else
      responses[href] = cjson.decode(res:read_body())
    end
  end
end


function string:split(sep)
  local sep, fields = sep or ":", {}
  local pattern = string.format("([^%s]+)", sep)
  self:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end

function table_len (T)
  local count = 0
  for k,v in pairs(T) do
    count = count + 1
  end
  return count
end

-- go through our hrefs updating our body data
for data_path, href in pairs(hrefs) do
  response = responses[href]
  to_update = body_data
  pieces = string.split(data_path, "/")
  num_pieces = table_len(pieces)
  last_piece = pieces[num_pieces]
  for i = 1, (num_pieces - 1) do
    token = pieces[i]
    to_update = to_update[token]
  end
  to_update[last_piece] = response
end

ngx.say(cjson.encode(body_data))

ngx.exit(200)
