local inspect   = require('inspect')
local strings   = require('strings')
local filepath  = require('filepath')

package.path    = filepath.join(filepath.dir(debug.getinfo(1).source), '../common/?.lua;') .. package.path
local functions = require('functions') 

contract = {
  name = 'dcdpcontract'
}

contract.tables = {
  code  = contract.name,
  scope = contract.name,
  table = 'tables',
  json  = true
}

contract.accounts = {
  code  = contract.name,
  scope = contract.name,
  table = 'accounts',
  json  = true,
  limit = 1000000
}

contract.accounts.history = {
  code  = 'acntcontract',
  scope = 'acntcontract',
  table = 'accounts',
  json  = true,
  limit = 1000000
}


function contract.get_count_of_tables(body)
  if table.getn(body['rows']) then
    return table.getn(body['rows'])
  else
    return 0
  end
end

function contract.get_basic_tables_info(body)
  basic_info = {}
  for n, row in pairs(body['rows']) do
    info = {
      id = row['id'],
      players_count = row['players_count'],
    sb = strings.split(row['small_blind'], " ")[1]}
    
    table.insert(basic_info, n, info)
    
  end
  
  return basic_info
end

function contract.get_detailed_table_info(body, id)
  for k, v in pairs(body['rows']) do
    
    if v['id'] == tonumber(id) then
      info = {}
      
      players = {}
      
      for i, player in pairs(v['players']) do
        
        k = {
          name = player['name'],
        stack = player['stack']}
        
        table.insert(players, i, k)
      end
      
    end
  end
  return players
  
end

function contract.get_body_tables(address)
  local nodeos_url = functions.build_nodeos_url('table', address)
  
  local body = functions.make_nodeos_request(nodeos_url, contract.tables)
  return body
end

function contract.get_poker_account(account)
  found = false
  current_network_player_summary = {}
  local nodeos_url = functions.build_nodeos_url('table', settings.networks.current.address)
  local current_network_accounts_info = functions.make_nodeos_request(nodeos_url, contract.accounts)
  for _, current_network_account in pairs(current_network_accounts_info['rows']) do
    if current_network_account['name_'] == account then
      found = true
      current_network_player_summary = current_network_account
      if current_network_account['table_id_'][1] then
        now_playing = 'Yes. On table with id ' .. current_network_account['table_id_'][1]
      else
        now_playing = 'No'
      end
    end
  end
  if settings.networks.abandoned then
    for _, v in pairs(settings.networks.abandoned) do
      local nodeos_url = functions.build_nodeos_url('table', v.address)
      local old_network_accounts_info = functions.make_nodeos_request(nodeos_url, contract.accounts)
      for _, old_network_account in pairs(old_network_accounts_info['rows']) do
        if old_network_account['name_'] == account then
          if found == false then
      	    found = true
            current_network_player_summary = old_network_account
          else
      	    current_network_player_summary['rake']          = string.format("%4.4f EOS", tonumber(strings.split(current_network_player_summary['rake'], " ")[1]) + tonumber(strings.split(old_network_account['rake'], " ")[1]))
      	    current_network_player_summary['total_win']     = string.format("%4.4f EOS", tonumber(strings.split(current_network_player_summary['total_win'], " ")[1]) + tonumber(strings.split(old_network_account['total_win'], " ")[1]))
      	    current_network_player_summary['total_loss']    = string.format("%4.4f EOS", tonumber(strings.split(current_network_player_summary['total_loss'], " ")[1]) + tonumber(strings.split(old_network_account['total_loss'], " ")[1]))
      	    current_network_player_summary['count_of_wins'] = current_network_player_summary['count_of_wins'] + old_network_account['count_of_wins']
      	    current_network_player_summary['count_of_defeats'] = current_network_player_summary['count_of_defeats'] + old_network_account['count_of_defeats']
      	    current_network_player_summary['penalty_count'] = current_network_player_summary['penalty_count'] + old_network_account['penalty_count']
      	    current_network_player_summary['penalty']       = string.format("%4.4f EOS", tonumber(strings.split(current_network_player_summary['penalty'], " ")[1]) + tonumber(strings.split(old_network_account['penalty'], " ")[1]))
          end
        end
      end
    end
  end
  if contract.accounts.history then
    local nodeos_url = functions.build_nodeos_url('table', settings.networks.current.address)
    local history_accounts_info = functions.make_nodeos_request(nodeos_url, contract.accounts.history)
    for _, history_network_account in pairs(history_accounts_info['rows']) do
      if history_network_account['name'] == account then
        if found == false then
          print('asdfsafd')
    	    found = true
          current_network_player_summary = history_network_account
        else
    	    current_network_player_summary['rake']          = string.format("%4.4f EOS", tonumber(strings.split(current_network_player_summary['rake'], " ")[1]) + tonumber(strings.split(history_network_account['rake'], " ")[1]))
    	    current_network_player_summary['total_win']     = string.format("%4.4f EOS", tonumber(strings.split(current_network_player_summary['total_win'], " ")[1]) + tonumber(strings.split(history_network_account['total_win'], " ")[1]))
    	    current_network_player_summary['total_loss']    = string.format("%4.4f EOS", tonumber(strings.split(current_network_player_summary['total_loss'], " ")[1]) + tonumber(strings.split(history_network_account['total_loss'], " ")[1]))
    	    current_network_player_summary['count_of_wins'] = current_network_player_summary['count_of_wins'] + history_network_account['count_of_wins']
    	    current_network_player_summary['count_of_defeats'] = current_network_player_summary['count_of_defeats'] + history_network_account['count_of_defeats']
    	    current_network_player_summary['penalty_count'] = current_network_player_summary['penalty_count'] + history_network_account['penalty_count']
    	    current_network_player_summary['penalty']       = string.format("%4.4f EOS", tonumber(strings.split(current_network_player_summary['penalty'], " ")[1]) + tonumber(strings.split(history_network_account['penalty'], " ")[1]))
        end
      end
    end
  end

  if found == false then
    print(" [ WARN ] Account "..account.." not found")
    return nil
  else
    info = {
    totalWins    = current_network_player_summary['total_win'],
    totalLoss    = current_network_player_summary['total_loss'],
    profit       = string.format("%4.4f EOS", tonumber(strings.split(current_network_player_summary['total_win'], " ")[1]) - tonumber(strings.split(current_network_player_summary['total_loss'], " ")[1])),
    rake         = current_network_player_summary['rake'],
    wins         = current_network_player_summary['count_of_wins'],
    loses        = current_network_player_summary['count_of_defeats'],
    penaltyCount = current_network_player_summary['penalty_count'],
    penaltyFee   = current_network_player_summary['penalty'],
    nowPlaying   = now_playing,
    lastConnectionTime = current_network_player_summary['connection_time']}
    return info
  end
end
  
return contract
