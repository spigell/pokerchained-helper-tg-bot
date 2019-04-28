
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
      elseif strings.has_prefix(command, "/tables") then
      	body = get_body_tables()

        tables_info = get_basic_tables_info(body)
        reply_markup = {}

        reply_markup.inline_keyboard = {}
        for k,v in pairs(tables_info) do
          big_blind = string.format("%4.4f", tonumber(v['sb']) * 2)

          text = "Table ID:"..v['id'].." ( "..v['sb'].."/"..big_blind.." EOS, "..tostring(v['players_count'])..'/6 )'
          callback_data_tables = v['id']
          cl = { { text = text, callback_data = callback_data_tables} }

          table.insert(reply_markup.inline_keyboard, k, cl)

        end

        count_tables = get_count_of_tables(body)
        if count_tables == 0 then
          msg = "There is no one on tables right now!"

        else
          msg = tostring(count_tables).." running tables. You can see addtional info by clicking on buttons below."
        end  
        local k, err = bot:sendMessage({
          chat_id = upd.message.chat.id,
          text = msg,
	      reply_to_message_id = upd.message.message_id,
          reply_markup = reply_markup
        })

        if err then error(err) end

      elseif strings.has_prefix(command, "/account")then

      	full_command = string.match(command, '^/account.*')

      	account = strings.split(full_command, " ")[2]

      	if account then 

      	  msg = "Info about account "..account.."\n"

      	  info = get_pocker_account(account)

      	  if info ~= nil then
      	    msg = msg..inspect(info)
      	  else
      	  	msg = "Account not found or some error occured. Account "..account.." exists?"
      	  end

      	else
      	  msg = 'Account name required'

      	end

        local _, err = bot:sendMessage({
          chat_id = upd.message.chat.id,
	      reply_to_message_id = upd.message.message_id,
          text = msg
        })

      end
    end

    elseif upd.callback_query then
      body = get_body_tables()

      msg = "Info About Table with id "..upd.callback_query.data.."\n Players:"

      info = get_detailed_table_info(body, upd.callback_query.data)

      local players_templates =  [[
  player:   %s
    stack:   %s
	   ]]

      for k,v in pairs(info) do
      	player = string.format(
      		players_templates,
      		v['name'],
      	    v['stack'])
      	msg = msg.."\n"..player
      end

	  local k, err = bot:sendMessage({
	    chat_id = upd.callback_query.message.chat.id,
	    message_id = upd.callback_query.message.message_id,
	    reply_to_message_id = upd.callback_query.message.message_id,
	    text = msg

      })

    elseif upd.edited_message then
      bot:sendMessage({
        chat_id = upd.edited_message.chat.id,
        reply_to_message_id = upd.edited_message.message_id,
        text = "Edited messages not supported yet",
    })

    else
      bot:sendMessage({
        chat_id = upd.message.chat.id,
        reply_to_message_id = upd.message.message_id,
        text = "I do not understand you. Please use /help",
    })
    end
  end
  time.sleep(0.5)
end
