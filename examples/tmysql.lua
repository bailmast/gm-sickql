local sickDB = SickQL:New('TMySQL', '127.0.0.1', 3306, 'root', 'root', 'sick')

function sickDB:OnConnected()
  print("TMySQL is for happy people :)")

  self:Query('SELECT version();')
    :SetOnSuccess(function(q, data)
      print("Hi! I'm TMySQL and my version is " .. data[1]['version()'])
    end)
    :SetOnError(function(q, why)
      print('Something went wrong! Why: ' .. why)
    end)
    :Start()
end

function sickDB:OnConnectionFailed(why)
  print('Connection failed: ' .. why)
end

sickDB:Connect()
