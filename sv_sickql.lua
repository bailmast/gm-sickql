SickQL = SickQL or {}

if util.IsBinaryModuleInstalled('mysqloo') then
  require('mysqloo')
end

if util.IsBinaryModuleInstalled('tmysql4') then
  require('tmysql4')

  SickQL.TMySQL_HookFormat = 'SickQL::TMySQLPolling(%s, %s, %s, %s, %s)' -- host, username, password, database, port
end

SickQL.Implementations = SickQL.Implementations or {
  ['SQLite'] = {
    Create = function(conn) return nil --[[ vdb ]], nil --[[ err ]] end,
    Connect = function(db) db:OnConnected() end,
    Query = function(vdb, q)
      local res = sql.Query(q.String)
      if res == false then
        q:OnError(sql.LastError())
        return
      end

      local data = res or {}
      q:OnSuccess(data)
    end,
    Disconnect = function(vdb, conn) end,
    Escape = function(vdb, str) return sql.SQLStr(str, true) end,
  },
  ['MySQLOO'] = {
    Create = function(conn)
      return mysqloo.connect(conn.Host, conn.Username, conn.Password, conn.DatabaseName, conn.Port), nil --[[ err ]]
    end,
    Connect = function(db)
      local vdb = db.VendorDatabase

      function vdb:onConnected()
        db:OnConnected()
      end

      function vdb:onConnectionFailed(why)
        db:OnConnectionFailed(why)
      end

      vdb:connect()
    end,
    Query = function(vdb, q)
      local vq = vdb:query(q.String)

      function vq:onSuccess(data)
        q:OnSuccess(data)
      end

      function vq:onError(why)
        q:OnError(why)
      end

      vq:start()
    end,
    Disconnect = function(vdb, conn) vdb:disconnect() end,
    Escape = function(vdb, str) return vdb:escape(str) end,
  },
  ['TMySQL'] = {
    Create = function(conn)
      return tmysql.Create(conn.Host, conn.Username, conn.Password, conn.DatabaseName, conn.Port)
    end,
    Connect = function(db)
      local conn = db.ConnectionInfo
      local hookTag = string.format(SickQL.TMySQL_HookFormat, conn.Host, conn.Username, conn.Password, conn.DatabaseName, conn.Port)

      if hook.GetTable()['Think'][hookTag] ~= nil then
        db:OnConnectionFailed("TMySQL can't handle multiple connections to one database!")

        return
      end

      local success, err = db.VendorDatabase:Connect()
      if not success then
        db:OnConnectionFailed(err)

        return
      end

      db:OnConnected()

      hook.Add('Think', hookTag, function() db.VendorDatabase:Poll() end)
    end,
    Query = function(vdb, q)
      vdb:Query(q.String, function(res)
        res = res[1]
        if res == nil then
          q:OnError('Result is nil!')

          return
        end

        if res.error ~= nil then
          q:OnError(res.error)

          return
        end

        q:OnSuccess(res.data)
      end)
    end,
    Disconnect = function(vdb, conn)
      hook.Remove('Think', SickQL.TMySQL_HookFormat:format(conn.Host, conn.Username, conn.Password, conn.DatabaseName, conn.Port))
      vdb:Disconnect()
    end,
    Escape = function(vdb, str) return vdb:Escape(str) end,
  }
}

local DATABASE_META = {}
DATABASE_META.__index = DATABASE_META

--- Creates and prepares your database instance before connecting to it.
--- @param impl string
--- @param host? string
--- @param port? number
--- @param username? string
--- @param password? string
--- @param database? string
--- @return table
--- @return string?
function SickQL:New(impl, host, port, username, password, database)
  local db = setmetatable({
    Implementation = self.Implementations[impl],
    VendorDatabase = nil,
    ConnectionInfo = {
      Host = host,
      Port = port,
      Username = username,
      Password = password,
      DatabaseName = database
    }
  }, DATABASE_META)

  local vdb, err = db.Implementation.Create(db.ConnectionInfo)
  db.VendorDatabase = vdb

  return db, err
end

--- Connect database itself.
--- @return table
function DATABASE_META:Connect()
  self.Implementation.Connect(self)

  return self
end

--- Disconnect from database.
function DATABASE_META:Disconnect()
  self.Implementation.Disconnect(self.VendorDatabase, self.ConnectionInfo)
end

--- Escape a string using a method provided by the database vendor.
--- @param str string
--- @return string
function DATABASE_META:Escape(str)
  return self.Implementation.Escape(self.VendorDatabase, str)
end

local QUERY_META = {}
QUERY_META.__index = QUERY_META

--- Prepare query so you can change `OnSuccess` and `OnError` functions.
--- @param str string
--- @return table
function DATABASE_META:Query(str)
  return setmetatable({
    String = str,
    Database = self
  }, QUERY_META)
end

--- @param cback fun(q: Query, data: table)
--- @return table
function QUERY_META:SetOnSuccess(cback)
  self.OnSuccess = cback

  return self
end

--- @param cback fun(q: Query, why: string)
--- @return table
function QUERY_META:SetOnError(cback)
  self.OnError = cback

  return self
end

--- Start query itself.
function QUERY_META:Start()
  local db = self.Database

  db.Implementation.Query(db.VendorDatabase, self)
end
