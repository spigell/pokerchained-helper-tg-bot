inspect = require("inspect")
strings = require("strings")

function bot_help(bot, upd)
  local _, err = bot:sendMessage({
    chat_id = upd.message.chat.id,
    text = [[
/help                        - this message
/start                       - start bot (show main menu)
/tables                      - get running tables
/account account name        - get brief stats about player
]]
  })
  if err then error(err) end
end

function bot_start(bot, upd)
  keyboard = { { get_table_button() }, { get_player_info_button() } }
  reply_markup = {}

  reply_markup = {
    keyboard = keyboard,
    resize_keyboard = true,
    one_time_keyboard = true
  }
  print(inspect(reply_markup))

  local _, err = bot:sendMessage({
    chat_id = upd.message.chat.id,
    text = "Hi! I am bot for [PockerChained](https://pokerchained.com). Author - @Spigell. Please use buttons or read /help",
    reply_markup = reply_markup,
    parse_mode = "Markdown"
  })
  if err then error(err) end
end

function tables(bot, upd)

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
end

function sent_player_stats(bot, data, account)

  	if account then 

      msg = "😎 Info about account *"..account.."*\n"

  	  info = get_pocker_account(account)

  	  if info ~= nil then
        msg = msg.."\n"..table_to_string(info)
  	  else
  	  	msg = "Account not found or some error occured. Account "..account.." exists? Is it a pokerchained player?"
  	  end

  	else
  	  msg = 'Account name required. Please try again'
  	end

    local _, err = bot:sendMessage({
      chat_id = data.chat.id,
      text = msg,
      parse_mode = 'Markdown'
    })

end

function sent_detailed_table_info(bot, upd)
  local body = get_body_tables()

  local msg = "Info About Table with id "..upd.callback_query.data.."\n Players:"

  local info = get_detailed_table_info(body, upd.callback_query.data)

  local players_templates =  [[
  player:   %s
    stack:   %s
  ]]

  reply_markup = {}

  reply_markup.inline_keyboard = {}

  for k,v in pairs(info) do
    player = string.format(
      players_templates,
      v['name'],
      v['stack'])
      msg = msg.."\n"..player
      cl = { { text = 'Stats for '..v['name'], callback_data = '/account '..v['name']} }
      table.insert(reply_markup.inline_keyboard, k, cl)
  end


  local k, err = bot:sendMessage({
  chat_id = upd.callback_query.message.chat.id,
  message_id = upd.callback_query.message.message_id,
  reply_to_message_id = upd.callback_query.message.message_id,
  reply_markup = reply_markup,
  text = msg

  })
end

function read_player_name(bot, upd)
  msg = get_initial_player_message()
  reply_markup = {
    force_reply = true
  }
  local _, err = bot:sendMessage({
    chat_id = upd.message.chat.id,
    text = msg,
    reply_to_message_id = upd.message.message_id,
    reply_markup = reply_markup
  })
  if err then error(err) end

end

function send_current_user_stats(bot, upd)
  local _, err = bot:sendMessage({
    chat_id = upd.message.chat.id,
    text = "😔 Not implemented yet. Sorry.",
    reply_to_message_id = upd.message.message_id,
  })
  if err then error(err) end
end

function get_initial_player_message()
  return "Please type name of player"
end

function get_table_button()
  return "🤔Tables"
end

function get_player_info_button()
  return "😎 Player info"
end
