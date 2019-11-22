local plugin   = require('plugin')
local filepath = require('filepath')
local time     = require('time')

local current_dir = filepath.dir(debug.getinfo(1).source)
local bot = plugin.do_file(filepath.join(current_dir, "telegram", "bot.lua"))
bot:run()

-- supervisor loop
while true do
  time.sleep(1)
  if not bot:is_running() then
    print("bot error:\n", tostring(bot:error()), "\n will restart it")
    bot:run()
  end
end
