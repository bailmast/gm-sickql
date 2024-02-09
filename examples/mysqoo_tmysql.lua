-- Same code for MySQLOO! Just don't forget to change vendor!
local sickDB = SickQL:New('TMySQL', '127.0.0.1', 3306, 'root', 'root', 'sick')

function sickDB:OnConnected()
  print("TMySQL is for happy people :)")

  local q = self:Query('SELECT version();')

  function q:OnSuccess(data)
    print("Hi! I'm TMySQL and my version is " .. data[1]['version()'])
  end

  function q:OnError(why)
    print('Something went wrong! Why: ' .. why)
  end
end

function sickDB:OnConnectionFailed(why)
  print('Connection failed: ' .. why)
end

sickDB:Connect()
