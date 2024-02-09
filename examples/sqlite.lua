local sickDB = SickQL:New('SQLite')

function sickDB:OnConnected()
  print("MySQLite is boring! But it's connected!")

  local q = self:Query('SELECT sqlite_version();')

  function q:OnSuccess(data)
    print('Your beatiful and boring MySQLite version is ' .. data[1]['sqlite_version()'])
  end

  function q:OnError(why)
    print('Something went wrong! Why: ' .. why)
  end
end

function sickDB:OnConnectionFailed(why)
  -- unreachable in MySQLite
end

sickDB:Connect()
