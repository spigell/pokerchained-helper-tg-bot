local http      = require('http')
local inspect   = require('inspect')
local strings   = require('strings')
local filepath  = require('filepath')
local telegram  = require('telegram')
local strings   = require('strings')
local ioutil    = require('ioutil')
local time      = require('time')
local yaml      = require('yaml')


package.path    = filepath.dir(debug.getinfo(1).source) .. '/?.lua;'.. package.path
package.path    = filepath.dir(debug.getinfo(1).source) .. '/../common/?.lua;'.. package.path
local utils     = require('utils')
local functions = require('functions')

local settings_file = os.getenv('POCKERCHAINED_BOT_SETTINGS')
if os.getenv('POCKERCHAINED_BOT_SETTINGS') then
  settings_file = os.getenv('POCKERCHAINED_BOT_SETTINGS')
else
  settings_file = settings
end

print('[INIT] load settings from config ' .. settings_file)
local data, err = ioutil.read_file(settings_file)
if err then error(err) end
-- settings are global. FIX ME
settings, err = yaml.decode(data)
if err then error(err) end

-- Main
local client = http.client()
local bot    = telegram.bot(settings.telegram.token, client)

function check() 
  local updates, err = bot:getUpdates()
  if err then error(err) end

  for _, upd in pairs(updates) do

  	if upd.message and upd.message.entities and upd.message.entities[1] then
      if upd.message.entities[1].type == 'bot_command' then
  	    command = upd.message.text
  	    if strings.has_prefix(command, "/help") then
  	  	  utils.bot_help(bot, upd)
  	    elseif strings.has_prefix(command, "/start") then
  	  	  utils.bot_start(bot, upd)
        elseif strings.has_prefix(command, "/tables") then
      	  utils.send_tables(bot, upd)
        elseif strings.has_prefix(command, "/account") then
          local account = functions.get_player_name_from_command(command)
          print(inspect(upd.message))
          utils.sent_player_stats(bot, upd.message, account)
        else
  	  	  utils.bot_help(bot, upd)
  	    end
  	  end

  -- callbacks
    elseif upd.callback_query then
      if strings.has_prefix(upd.callback_query.data, '/account') then
        local account = functions.get_player_name_from_command(upd.callback_query.data)
        utils.sent_player_stats(bot, upd.callback_query.message, account)
      elseif strings.has_suffix(upd.callback_query.message.text, "clicking on buttons below.") then
        utils.sent_detailed_table_info(bot, upd)
      else
        print('[ WARN ] Unsupported callback query'..inspect(upd))
      end

    elseif upd.message and upd.message.reply_to_message then
      if upd.message.reply_to_message.text == get_initial_player_message() then
      	account = upd.message.text 
        utils.sent_player_stats(bot, upd.message, account)
      end

    elseif upd.edited_message then
      bot:sendMessage({
        chat_id = upd.edited_message.chat.id,
        reply_to_message_id = upd.edited_message.message_id,
        text = "Edited messages not supported yet",
    })

    else
      if upd.message.text == get_table_button() then
      	utils.send_tables(bot, upd)
      elseif upd.message.text == get_player_info_button() then
      	utils.ask_player_name(bot, upd)
      elseif upd.message.text == 'My statistics' then
      	utils.send_current_user_stats(bot, upd)
      else
      bot:sendMessage({
        chat_id = upd.message.chat.id,
        reply_to_message_id = upd.message.message_id,
        text = "I do not understand you. Please use /help",
      })
    end
  end
  end
end

while true do
  check()
  time.sleep(0.1)
end
