local sickDB = SickQL:New('MySQLOO', '127.0.0.1', 3306, 'root', 'root', 'sick')

function sickDB:OnConnected()
  print("MySQLOO is for sad people :(")

  local q = self:Query('SELECT version();')

  function q:OnSuccess(data)
    print("Hi! I'm MySQLOO and my version is " .. data[1]['version()'])
  end

  function q:OnError(why)
    print('Something went wrong! Why: ' .. why)
  end

  q:Start()
end

function sickDB:OnConnectionFailed(why)
  print('Connection failed: ' .. why)
end

sickDB:Connect()
