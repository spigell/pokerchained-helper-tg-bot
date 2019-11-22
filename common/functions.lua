local http = require('http')
local json = require('json')
local strings = require('strings')

local functions = {}

function functions.build_nodeos_url(request_type, address)
  if request_type == 'table' then
    api_uri = '/v1/chain/get_table_rows'
  else
    print('[ ERROR ] Not supported type for building url')
    os.exit(1)
  end
  
  nodeos_url = address .. api_uri
  return nodeos_url
end

function functions.make_nodeos_request(nodeos_url, data)
  
  local client = http.client({insecure_ssl = true})
  
  local body = json.encode(data)
  
  local request = http.request("POST", nodeos_url, body)
  local result, err = client:do_request(request)
  
  if not(result.code == 200) then
    print(result.body)
    error('bad http code - '..result.code)
  end
  return json.decode(result.body)
  
end
function functions.table_to_string(tbl)
  local result = ""
  for k, v in pairs(tbl) do
    if type(k) == "string" then
      result = result.." "..k.." " .. "="
    end
    -- Check the value type
    if type(v) == "table" then
      result = result..table_to_string(v)
    elseif type(v) == "boolean" then
      result = result..tostring(v)
    else
      result = result.." "..v.." "
    end
    result = result.."\n"
  end
  if result ~= "" then
    result = result:sub(1, result:len() - 1)
  end
  return result
end

function functions.get_player_name_from_command(command)
  full_command = string.match(command, '^/account.*')
  account, err = strings.split(full_command, " ")[2]
  if err then
    return nil
  else
    return account
  end
end

return functions
