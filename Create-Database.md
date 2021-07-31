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