# SickQL

Garry's Mod database interface that supports [SQLite](https://wiki.facepunch.com/gmod/sql), [MySQLOO](https://github.com/FredyH/MySQLOO) & [TMySQL](https://github.com/SuperiorServers/gm_tmysql4).

## Usage

[See Examples](examples/)

## Functions & Methods

### Database

```lua
Database SickQL:New(string impl, string host, integer port, string username, string password, string database)
```

```lua
Database Database:Connect()
```

```lua
Database Database:Disconnect()
```

```lua
string Database:Escape(string str)
```

```lua
Query Database:Query(string str)
```

### Query

```lua
QUERY:Start()
```

## Callbacks

### Database

```lua
Database:OnConnected()
```

```lua
Database:OnConnectionFailed(string why)
```

### Query

```lua
Query:OnSuccess(table data)
```

```lua
Query:OnError(string why)
```
