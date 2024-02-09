SickQL = SickQL or {}

local CURRENT_VERSION = 240209
if SickQL._VERSION and (SickQL._VERSION <= CURRENT_VERSION) then return end
SickQL._VERSION = CURRENT_VERSION

if util.IsBinaryModuleInstalled('mysqloo') then
  require('mysqloo')
end

if util.IsBinaryModuleInstalled('tmysql4') then
  require('tmysql4')

  SickQL.TMySQL_HookFormat = 'SickQL::TMySQLPolling(%s)'
  SickQL.TMySQL_LastConnection = SickQL.TMySQL_LastConnection or 0
end

SickQL.Implementations = SickQL.Implementations or {
  ['MySQLite'] = {
    Create = function(conn)
      return nil --[[ vdb ]], nil --[[ err ]]
    end,
    Connect = function(db)
      db:OnConnected()
    end,
    Query = function(vdb, q)
      local res = sql.Query(q.String)
      if res == false then
        q:OnError(sql.LastError())
        return
      end

      local data = res or {}
      q:OnSuccess(data)
    end,
    Disconnect = function(vdb, conn) end
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
    Disconnect = function(vdb, conn)
      vdb:disconnect()
    end
  },
  ['TMySQL'] = {
    Create = function(conn)
      return tmysql.Create(conn.Host, conn.Username, conn.Password, conn.DatabaseName, conn.Port)
    end,
    Connect = function(db)
      local success, err = db.VendorDatabase:Connect()
      if not success then
        db:OnConnectionFailed(err)
        return
      end

      db:OnConnected()

      SickQL.TMySQL_LastConnection = SickQL.TMySQL_LastConnection + 1
      db.ConnectionInfo.TMySQLConnection = SickQL.TMySQL_LastConnection

      hook.Add('Think', SickQL.TMySQL_HookFormat:format(SickQL.TMySQL_LastConnection), function()
        db.VendorDatabase:Poll()
      end)
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
      hook.Remove('Think', SickQL.TMySQL_HookFormat:format(conn.TMySQLConnection))
      vdb:Disconnect()
    end
  }
}

local DATABASE_META = {
  OnConnected = function(db) end,
  OnConnectionFailed = function(db, why) end
}
DATABASE_META.__index = DATABASE_META

---Creates and prepares your database instance before connecting to it.
---@param impl string
---@param host? string
---@param port? number
---@param username? string
---@param password? string
---@param database? string
---@return table
---@return string?
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

---Connect database itself.
---@return table
function DATABASE_META:Connect()
  self.Implementation.Connect(self)
  return self
end

---Disconnect from database.
function DATABASE_META:Disconnect()
  self.Implementation.Disconnect(self.VendorDatabase, self.ConnectionInfo)
end

local QUERY_META = {
  OnSuccess = function(q, data) end,
  OnError = function(q, why) end
}
QUERY_META.__index = QUERY_META

---Prepare query so you can change `OnSuccess` and `OnError` functions.
---@param str string
---@return table
function DATABASE_META:Query(str)
  return setmetatable({
    String = str,
    Database = self
  }, QUERY_META)
end

---Start query itself.
function QUERY_META:Start()
  local db = self.Database
  db.Implementation.Query(db.VendorDatabase, self)
end
