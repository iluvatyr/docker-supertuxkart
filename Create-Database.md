Use following commands in following order:

docker exec -it <supertuxkart container name> bash
cd /stk
sqlite3 stkservers.db

1) Copy everything below and paste it inside the database
2) Type ".quit" to exit the database.
3) Enter the server_config.xml and search for sql-management value. Set it to true like below
 ```
    <!-- Use sql database for handling server stats and maintenance, STK needs to be compiled with sqlite3 supported. -->
    <sql-management value="true" />
 ```
4) Change the table name for records table to "v1_server_config_results" (or something else if you named it differently) so that it looks like below
   The naming structure of the records table is "v1_servername_results"  (servername = server_config if server_config.xml is your servers config.)

    ```
    <!-- When non-empty, server is telling whether a player has beaten a server record, records are taken from the table specified in this field. So it can be the results table for this server or for all servers hosted on the machine. -->
    <records-table-name value="v1_server_config_results" />
    ```
5) Search for "store-results" and also set it to true like below

    <!-- When true, stores race results in a separate table for each server. -->
    <store-results value="true" />

## Copy this and paste after the sqlite3 stkservers.db command

```
CREATE TABLE IF NOT EXISTS v1_server_config_stats
(
    host_id INTEGER UNSIGNED NOT NULL PRIMARY KEY, -- Unique host id in STKHost of each connection session for a STKPeer
    ip INTEGER UNSIGNED NOT NULL, -- IP decimal of host
    ipv6 TEXT NOT NULL DEFAULT '', -- IPv6 (if exists) in string of host (only created if IPv6 server)
    port INTEGER UNSIGNED NOT NULL, -- Port of host
    online_id INTEGER UNSIGNED NOT NULL, -- Online if of the host (0 for offline account)
    username TEXT NOT NULL, -- First player name in the host (if the host has splitscreen player)
    player_num INTEGER UNSIGNED NOT NULL, -- Number of player(s) from the host, more than 1 if it has splitscreen player
    country_code TEXT NULL DEFAULT NULL, -- 2-letter country code of the host
    version TEXT NOT NULL, -- SuperTuxKart version of the host
    os TEXT NOT NULL, -- Operating system of the host
    connected_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Time when connected
    disconnected_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Time when disconnected (saved when disconnected)
    ping INTEGER UNSIGNED NOT NULL DEFAULT 0, -- Ping of the host
    packet_loss INTEGER NOT NULL DEFAULT 0, -- Mean packet loss count from ENet (saved when disconnected)
    addon_karts_count INTEGER UNSIGNED NOT NULL DEFAULT 0, -- Number of addon karts of the host
    addon_tracks_count INTEGER UNSIGNED NOT NULL DEFAULT 0, -- Number of addon tracks of the host
    addon_arenas_count INTEGER UNSIGNED NOT NULL DEFAULT 0, -- Number of addon arenas of the host
    addon_soccers_count INTEGER UNSIGNED NOT NULL DEFAULT 0 -- Number of addon soccers of the host
) WITHOUT ROWID;

CREATE TABLE IF NOT EXISTS v1_countries
(
    country_code TEXT NOT NULL PRIMARY KEY UNIQUE, -- Unique 2-letter country code
    country_flag TEXT NOT NULL, -- Unicode country flag representation of 2-letter country code
    country_name TEXT NOT NULL -- Readable name of this country
) WITHOUT ROWID;

CREATE TABLE ip_ban
(
    ip_start INTEGER UNSIGNED NOT NULL UNIQUE, -- Starting of ip decimal for banning (inclusive)
    ip_end INTEGER UNSIGNED NOT NULL UNIQUE, -- Ending of ip decimal for banning (inclusive)
    starting_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Starting time of this banning entry to be effective
    expired_days REAL NULL DEFAULT NULL, -- Days for this banning to be expired, use NULL for a permanent ban
    reason TEXT NOT NULL DEFAULT '', -- Banned reason shown in user stk menu, can be empty
    description TEXT NOT NULL DEFAULT '', -- Private description for server admin
    trigger_count INTEGER UNSIGNED NOT NULL DEFAULT 0, -- Number of banning triggered by this ban entry
    last_trigger TIMESTAMP NULL DEFAULT NULL -- Latest time this banning entry was triggered
);

CREATE TABLE ipv6_ban
(
    ipv6_cidr TEXT NOT NULL UNIQUE, -- IPv6 CIDR range for banning (for example 2001::/64), use /128 for a specific ip
    starting_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Starting time of this banning entry to be effective
    expired_days REAL NULL DEFAULT NULL, -- Days for this banning to be expired, use NULL for a permanent ban
    reason TEXT NOT NULL DEFAULT '', -- Banned reason shown in user stk menu, can be empty
    description TEXT NOT NULL DEFAULT '', -- Private description for server admin
    trigger_count INTEGER UNSIGNED NOT NULL DEFAULT 0, -- Number of banning triggered by this ban entry
    last_trigger TIMESTAMP NULL DEFAULT NULL -- Latest time this banning entry was triggered
);

CREATE TABLE online_id_ban
(
    online_id INTEGER UNSIGNED NOT NULL UNIQUE, -- Online id from STK addons database for banning
    starting_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Starting time of this banning entry to be effective
    expired_days REAL NULL DEFAULT NULL, -- Days for this banning to be expired, use NULL for a permanent ban
    reason TEXT NOT NULL DEFAULT '', -- Banned reason shown in user stk menu, can be empty
    description TEXT NOT NULL DEFAULT '', -- Private description for server admin
    trigger_count INTEGER UNSIGNED NOT NULL DEFAULT 0, -- Number of banning triggered by this ban entry
    last_trigger TIMESTAMP NULL DEFAULT NULL -- Latest time this banning entry was triggered
);

CREATE TABLE player_reports
(
    server_uid TEXT NOT NULL, -- Report from which server unique id (config filename)
    reporter_ip INTEGER UNSIGNED NOT NULL, -- IP decimal of player who reports
    reporter_ipv6 TEXT NOT NULL DEFAULT '', -- IPv6 (if exists) in string of player who reports (only needed for IPv6 server)
    reporter_online_id INTEGER UNSIGNED NOT NULL, -- Online id of player who reports, 0 for offline player
    reporter_username TEXT NOT NULL, -- Player name who reports
    reported_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Time of reporting
    info TEXT NOT NULL, -- Report info by reporter
    reporting_ip INTEGER UNSIGNED NOT NULL, -- IP decimal of player being reported
    reporting_ipv6 TEXT NOT NULL DEFAULT '', -- IPv6 (if exists) in string of player who reports (only needed for IPv6 server)
    reporting_online_id INTEGER UNSIGNED NOT NULL, -- Online id of player being reported, 0 for offline player
    reporting_username TEXT NOT NULL -- Player name being reported
);

CREATE TABLE v1_server_config_results
(
time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Timestamp of the result
username TEXT NOT NULL, -- User who set the result
venue TEXT NOT NULL, -- Track for a race
reverse TEXT NOT NULL, -- Direction
mode TEXT NOT NULL, -- Racing mode
laps INTEGER NOT NULL, -- Number of laps
result REAL NOT NULL -- Elapsed time for a race, possibly with autofinish 
);

```
 
# In case you have multiple Supertuxkart servers and both store players records:
Create a second table for records like this:
1) Copy everything below (change the table name accordingly), 
2) cd into the folder with the database
3) paste everything after entering the database using sqlite3 stkservers.db (or name of database you defined)
 
```
CREATE TABLE v1_server_config_2_results
(
time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Timestamp of the result
username TEXT NOT NULL, -- User who set the result
venue TEXT NOT NULL, -- Track for a race
reverse TEXT NOT NULL, -- Direction
mode TEXT NOT NULL, -- Racing mode
laps INTEGER NOT NULL, -- Number of laps
result REAL NOT NULL -- Elapsed time for a race, possibly with autofinish 
);
 ```
Then type ".quit" to exit the db.

# Make servers use combined results of more than one server:
If you want the servers to use results of both servers to say if someone beat a server record, meaning someone could beat a server record in server1 and in server2 it would not be beaten also until it is faster than that record of server1. 
1) Create a view of both records tables like shown below (using sqlite3 command again) 
2) Make sure to change the name after "FROM" to the records table names you created before of the single servers.
3) Inside the server_config.xml of each server, change the records table to use the all_results view. It will still log to its own table, but take results from all_results.
It will look like this afterwards inside each servers config.xml
 

    `<!-- When non-empty, server is telling whether a player has beaten a server record, records are taken from the table specified in this field. So it can be the results table for this server or for all servers hosted on the machine. -->`
    <records-table-name value="all_results" />
 
```
CREATE VIEW all_results AS SELECT server_name, time, username, venue, reverse, mode, laps, result FROM (
SELECT 'NAME1' AS server_name, time, username, venue, reverse, mode, laps, result FROM v1_server_config_results
UNION SELECT 'NAME2' AS server_name, time, username, venue, reverse, mode, laps, result FROM v1_server_config_2_results
) ORDER BY time DESC, result ASC;
```

 
# Other Views that can be created:
 ```
 CREATE VIEW all_players AS SELECT server_name, connected_time, online_id, username, ip, ip_readable, country_code, os FROM (
    SELECT 'Server1' AS server_name, connected_time, online_id, username, ip, ((ip >> 24) & 255) ||'.'|| ((ip >> 16) & 255) ||'.'|| ((ip >>  8) & 255) ||'.'|| ((ip ) & 255) AS ip_readable, country_code, os FROM v1_server_config_stats
    UNION SELECT 'Server2' AS server_name, connected_time, online_id, username, ip, ((ip >> 24) & 255) ||'.'|| ((ip >> 16) & 255) ||'.'|| ((ip >>  8) & 255) ||'.'|| ((ip ) & 255) AS ip_readable, country_code, os FROM v1_server2_config_stats
    UNION SELECT 'Server3' AS server_name, connected_time, online_id, username, ip, ((ip >> 24) & 255) ||'.'|| ((ip >> 16) & 255) ||'.'|| ((ip >>  8) & 255) ||'.'|| ((ip ) & 255) AS ip_readable, country_code, os FROM v1_server3_config_stats
) ORDER BY ip DESC;
 ```
