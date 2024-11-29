# SickQL

Garry's Mod database interface that supports [SQLite](https://wiki.facepunch.com/gmod/sql), [TMySQL](https://github.com/SuperiorServers/gm_tmysql4) & [MySQLOO](https://github.com/FredyH/MySQLOO).

## Usage

```lua
-- connection using any driver is thread-blocking
local connection, err = SickQL.New({
  Driver = 'tmysql', -- either sqlite, tmysql or mysqloo
  Hostname = 'localhost',
  Port = 3306,
  Username = 'root',
  Password = 'root',
  Database = 'sys',
})

if err ~= nil then
  print('Connection failed: ' .. err)
end

print('Database is connected!')

connection:Query('select version()', function(data)
  print('Database version is ' .. data[1]['version()'])
end, function(why)
  print('Failed to get version from query: ' .. why)
end)
```
