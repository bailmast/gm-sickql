if util.IsBinaryModuleInstalled('mysqloo') then
  require('mysqloo')
end

if util.IsBinaryModuleInstalled('tmysql4') then
  require('tmysql4')
end

SickQL = SickQL or {}
SickQL.Implementations = SickQL.Implementations or {}

SickQL.Implementations['sqlite'] = SickQL.Implementations['sqlite'] or {
  Connect = function(init)
    return nil, nil
  end,
  Escape = function(string)
    return sql.SQLStr(string, true)
  end,
  Query = function(driver, query, onData, onError)
    local res = sql.Query(query)
    if res == false then
      onError(sql.LastError())
      return
    end

    local data = res or {}
    onData(data)
  end,
  Disconnect = function(driver) end,
}

SickQL.Implementations['tmysql'] = SickQL.Implementations['tmysql'] or {
  Connect = function(init)
    local connection, error = tmysql.Connect(
      init.Hostname,
      init.Username,
      init.Password,
      init.Database,
      init.Port
    )

    if error then
      return nil, error
    end

    hook.Add('Think', string.format('SickQL::TMySQLPolling(%s)', connection), function()
      connection:Poll()
    end)

    return connection, nil
  end,
  Escape = function(driver, string)
    return driver:Escape(string)
  end,
  Query = function(driver, query, onData, onError)
    driver:Query(query, function(res)
      res = res[1]

      if res.status == true then
        onData(res.data)
      else
        onError(res.error)
      end
    end)
  end,
  Disconnect = function(driver)
    driver:Disconnect()
  end,
}

SickQL.Implementations['mysqloo'] = SickQL.Implementations['mysqloo'] or {
  Connect = function(init)
    local db = mysqloo.connect(
      init.Hostname,
      init.Username,
      init.Password,
      init.Database,
      init.Port
    )

    local err
    function db:onConnectionFailed(why)
      err = why
    end

    db:connect()
    db:wait()

    if db:status() == mysqloo.DATABASE_CONNECTED then
      return db, nil
    else
      return nil, err
    end
  end,
  Escape = function(driver, string)
    return driver:escape(string)
  end,
  Query = function(driver, query, onData, onError)
    local q = driver:query(query)

    function q:onSuccess(data)
      onData(data)
    end

    function q:onError(why)
      onError(why)
    end

    q:start()
  end,
  Disconnect = function(driver)
    driver:disconnect()
  end,
}

local CONNECTION_META = {}
CONNECTION_META.__index = CONNECTION_META

function CONNECTION_META:Escape(string)
  return self.impl.Escape(self.driver, string)
end

function CONNECTION_META:Query(query, onData, onError)
  onData = onData or function() end
  onError = onError or function() end
  return self.impl.Query(self.driver, query, onData, onError)
end

function CONNECTION_META:Disconnect()
  self.impl.Disconnect(self.driver)
end

function SickQL.New(init)
  local impl = SickQL.Implementations[init.Driver:lower()]
  if impl == nil then
    return nil, 'No such SickQL implementation!'
  end

  local driver, error = impl.Connect(init)
  if error ~= nil then
    return nil, error
  end

  return setmetatable({
    impl = impl,
    driver = driver,
  }, CONNECTION_META)
end
