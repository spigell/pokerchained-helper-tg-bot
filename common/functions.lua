local http = require("http")
local json = require("json")
local inspect = require("inspect")
local strings = require("strings")

function bot_help(bot, upd)
  local _, err = bot:sendMessage({
    chat_id = upd.message.chat.id,
    text = [[
/help                        - this message
/tables                      - get running tables
/account account name        - get brief stats about player
]]
  })
  if err then error(err) end
end


function build_nodeos_url(request_type, address)
  if request_type == 'table' then
  	api_uri = '/v1/chain/get_table_rows'
  else
  	print('[ ERROR ] Not supported type for building url')
  	os.exit(1)
  end

  nodeos_url = address..api_uri
  return nodeos_url
end

function make_nodeos_request(nodeos_url, data)

  local client = http.client({insecure_ssl=true})

  local body = json.encode(data)

  local request = http.request("POST", nodeos_url, body)
  local result, err = client:do_request(request)

    if not(result.code == 200) then
      print(result.body)
      error('bad http code - '..result.code)
    end

  return json.decode(result.body)

end


function get_count_of_tables(body)
  if table.getn(body['rows']) then
    return table.getn(body['rows'])
  else
  	return 0
  end
end

function get_basic_tables_info(body)
  basic_info = {}
  for n, row in pairs(body['rows']) do
  	info = {
      id = row['id'],
      players_count = row['players_count'],
      sb = strings.split(row['small_blind'], " ")[1]
    }

    table.insert(basic_info, n, info)


  end

  return basic_info
end

function get_detailed_table_info(body, id)
  for k, v in pairs(body['rows']) do

  	if v['id'] == tonumber(id) then
	  info = {}

  	  players = {}

  	  for i, player in pairs(v['players']) do


  	  	k = {
  	  	  name = player['name'],
  	  	  stack = player['stack']
  	    }

  	  	table.insert(players, i, k)
  	  end

    end
  end
  return players


end

function get_body_tables()
  local nodeos_url = build_nodeos_url('table', settings.node.address)
  --if log_level == 'debug' then print('[ DEBUG ] Node url is '..nodeos_url) end

  local body = make_nodeos_request(nodeos_url, settings.pockerchained.tables)
  return body
end

function get_pocker_account(account)
  local nodeos_url = build_nodeos_url('table', settings.node.address)
  local body = make_nodeos_request(nodeos_url, settings.pockerchained.accounts)
  found = false

  for _, a in pairs(body['rows']) do
    if a['name_'] == account then
      found = true

      info = {
        profit = string.format("%4.4f EOS", tonumber(strings.split(a['total_win'], " ")[1]) - tonumber(strings.split(a['total_loss'], " ")[1])),
        wins = a['count_of_wins'],
        loses = a['count_of_defeats'],
        total_win = a['total_win'],
        total_loss = a['total_loss'],
        penalty = a['penalty'],
        rake = a['rake'],
        last_connection_time = a['connection_time']
      }
    end
  end

  if found == false then
    print(" [ WARN ] Account "..account.." not found")
      return nil
  else
      return info
  end
end


function table_to_string(tbl)
    local result = ""
    for k, v in pairs(tbl) do
        if type(k) == "string" then
            result = result.." "..k.." ".."="
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
        result = result:sub(1, result:len()-1)
    end
    return result
end
