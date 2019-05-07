
local http = require("http")
local inspect = require("inspect")
local json = require("json")
local strings = require("strings")
local filepath = require("filepath")
local telegram = require("telegram")
local strings = require("strings")
local time = require("time")



package.path = filepath.dir(debug.getinfo(1).source)..'/common/?.lua;'.. package.path

local settings_file = os.getenv('POCKERCHAINED_BOT_SETTINGS')
if os.getenv('POCKERCHAINED_BOT_SETTINGS') then
  settings_file = os.getenv('POCKERCHAINED_BOT_SETTINGS')
else
  settings_file = settings
end


local settings = require(settings_file)
local functions = require("functions")
local functions = require("telegram_functions")

local log_level = os.getenv('LUA_BOT_LOG_LEVEL')
if log_level == 'debug' then print(inspect(settings)) end 

local client = http.client()
local bot = telegram.bot(settings.telegram.token, client)

local nodeos_url = build_nodeos_url('table', settings.node.address)
if log_level == 'debug' then print('[ DEBUG ] Node url is '..nodeos_url) end



-- main blocking loop
while true do

  local updates, err = bot:getUpdates()
  if err then error(err) end


  for _, upd in pairs(updates) do
  	if log_level == 'debug' then print(inspect(upd))end

  	if upd.message and upd.message.entities and upd.message.entities[1] then

      if upd.message.entities[1].type == 'bot_command' then
  	    command = upd.message.text
  	    if strings.has_prefix(command, "/help") then
  	  	  bot_help(bot, upd)
  	    elseif strings.has_prefix(command, "/start") then
  	  	  bot_start(bot, upd)
        elseif strings.has_prefix(command, "/tables") then
      	  tables(bot, upd)

        elseif strings.has_prefix(command, "/account") then
          local account = get_player_name_from_command(command)
          sent_player_stats(bot, upd.message, account)

        else
  	  	  bot_help(bot, upd)
  	    end
  	  end


    elseif upd.callback_query then

      if strings.has_prefix(upd.callback_query.data, "/account") then
        local account = get_player_name_from_command(upd.callback_query.data)
        sent_player_stats(bot, upd.callback_query.message, account)
      elseif strings.has_suffix(upd.callback_query.message.text, "clicking on buttons below.") then
        sent_detailed_table_info(bot, upd)
      else
        print('[ WARN ] Unsupported callback query'..inspect(upd))
	  end

    elseif upd.message and upd.message.reply_to_message then
      if upd.message.reply_to_message.text == get_initial_player_message() then
      	account = upd.message.text 
        sent_player_stats(bot, upd.message, account)
      end

    elseif upd.edited_message then
      bot:sendMessage({
        chat_id = upd.edited_message.chat.id,
        reply_to_message_id = upd.edited_message.message_id,
        text = "Edited messages not supported yet",
    })

    else
      if upd.message.text == get_table_button() then
      	tables(bot, upd)
      elseif upd.message.text == get_player_info_button() then
      	read_player_name(bot, upd)
      elseif upd.message.text == 'My statistics' then
      	send_current_user_stats(bot, upd)
      else
	    bot:sendMessage({
	      chat_id = upd.message.chat.id,
	      reply_to_message_id = upd.message.message_id,
	      text = "I do not understand you. Please use /help",
	    })
	  end
	end
  end
  time.sleep(0.5)
end
