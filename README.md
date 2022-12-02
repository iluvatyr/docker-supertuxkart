# Docker SuperTuxKart Server 

This is a docker image for deploying a [SuperTuxKart](https://supertuxkart.net) server. 
It is specifically designed for easy server setup so that anyone can deploy and manage a SuperTuxKart-Server without needing further knowledge. Just running the docker-run-command or docker-compose up is enough to get a functioning LAN or WAN-Server.

## How to use this image

The server should be configured using your own server config file. The config file template can be found [here](https://github.com/iluvatyr/docker-supertuxkart/blob/master/server_config.xml). Modify it according to your needs and mount it at `/stk/server_config.xml`. Not mounting it will use a default generated one and the server will be named STK-Server. 
Mounting it, and starting up the server may add more fields depending on the server version.

### Hosting a public/online/wan server

1) [Register](https://online.supertuxkart.net/register.php) a free STK account on online.supertuxkart.net if you do not have one already. 
2) If your firewall blocks incoming traffic by default, forward **port 2759** within the Router or VPS Firewall (or the custom port you configured within the server_config.xml ). Otherwise players cannot join.

### Starting server using docker-compose

1) Simply clone this repository via `git clone https://github.com/iluvatyr/docker-supertuxkart.git` or download the [docker-compose.yml](https://github.com/iluvatyr/docker-supertuxkart/blob/master/docker-compose-yml) to a location of your choice on your VPS/PC.
2) Edit the credentials (STK-username & STK-password) environment variables within the docker-compose.yml
3) Starting up the supertuxkart-server via `docker-compose up -d` will start a SuperTuxKart-Server with default configuration from server_config.xml shown in this repository.
**To customize your server, more has to be done:**
4) Download the [server_config.xml](https://github.com/iluvatyr/docker-supertuxkart/blob/master/server_config.xml) and uncomment the bindmount for it in the docker-compose.yml, if you wish to edit configuration options that cannot be changed with environmental variables (e.g. some database options)
5) Enable/Edit the optional environment variables and volume paths as you wish to the addon tracks, assets to be persistent through restarts, view logfiles on the host system etc or have a database. The options should be self explanatory. But some explanations can be found below. Read through them, to make sure you understood what needs to be done.
6) Folder structure should now be something like this, as an example with database, logs,addons,assets,and motd.txt are mounted on the host and persist, even if the container is removed (which is how it should be in this case, since you dont want to download addons+ assets everytime the container is started up):
```
    ./docker-compose.yml
    ./stk/server_config.xml
    ./stk/assets
    ./stk/addons
    ./stk/logs/stdout.log
    ./stk/logs/server_config.log
    ./stk/stkservers.db
    ./stk/motd.txt
```
Of course, you can also change the mounts within the docker-compose.yml and have a different folder structure)
7) After editing the environment variables as you wish, you can just like before get the server up and running by typing `docker-compose up -d` in your terminal. 
8) You can look at the logs by using `docker logs -f supertuxkart-server` or by viewing the mounted logfiles. Tom make sure, everything is running as it should, you can run your SuperTuxKart Game client and see if you can find, connect, and play on your newly created server (best to check from outside your local network if you are running a server from home)

### Running server using docker-run
Follow the same procedure as for docker-compose but in the end, start up the container with following command. `$(pwd)` just points to the location that you are currently in and should be changed to where your files reside or you only run the server by first running `cd /path-on-host/stk`

**Minimal**
```
docker run --name supertuxkart-server \
           -e STK_USERNAME=myusername \
           -e STK_PASSWORD=mypassword \
           -d \
           -p 2757:2757 \
           -p 2759:2759 \
           iluvatyr/supertuxkart:normal-1.4
```

**Customized Server with addons, database and other options set.**
Explanations can be visited within the docker-compose.yml
```
docker run --name supertuxkart-server \
      -e TZ=Europe/Berlin # (default UTC) \
      -e PUID=1337 \
      -e PGID=1337 \
      -e UPTIME_PUSH_URL=https://your-push-url.yourdomain.com/ \
      -e UPTIME_PUSH_PERIOD=300 \
      -e STK_USERNAME=your-stk-username \
      -e STK_PASSWORD=your_password \
      -e STK_PORT=2762 \
      -e STK_SERVER_CONF=server_config.xml \
      -e STK_AI_KARTS=2 \
      -e STK_FIREWALLED=false \
      -e STK_INSTALL_ADDONS=false \
      -e STK_UPDATE_ADDONS=false \
      -v $(pwd)/stk/assets/:/usr/local/share/supertuxkart/data/ \
      -v $(pwd)/stk/server_config.xml:/stk/server_config.xml \
      -v $(pwd)/stk/motd.txt:/stk/motd.txt \
      -v $(pwd)/stk/addons/:/home/supertuxkart/.local/share/supertuxkart/addons/ \
      -v $(pwd)/stk/stkservers.db:/stk/stkservers.db \
      -v $(pwd)/stk/replay/:/home/supertuxkart/.local/share/supertuxkart/replay/ \
      -v $(pwd)/stk/grandprix/:/home/supertuxkart/.local/share/supertuxkart/grandprix/ \
      -v $(pwd)/stk/screenshots:/home/supertuxkart/.local/share/supertuxkart/screenshots/ \
      -v $(pwd)/stk/logs/stdout.log:/home/supertuxkart/.config/supertuxkart/config-0.10/stdout.log \
      -v $(pwd)/stk/logs/server_config.log:/home/supertuxkart/.config/supertuxkart/config-0.10/server_config.log \
           iluvatyr/supertuxkart:normal-1.4
```

### Hosting a server in your local network (LAN)

You can use the same docker run as above
- **STK_USERNAME** and **STK_PASSWORD** not necessary
- Set **STK_FIREWALLED=true** 
- Usually you do not have to change firewallsettings within a local network, but if you cannot join a local server in your home network, besides everything configured correctly, it may be necessary to **forward port 2759 and 2757** ( lan server & lan local discovery) to your LAN-Network on the machine running the server and/or Router if the firewall blocks lan traffic. If you changed the ports, forward them accordingly.

### Adding addon tracks

**Manually**
1) Create a folder .e.g. /path_on/host/stk/addons
2) Add the folders of addon tracks into the folder
3) Mount it as shown above in the docker run command
More info on [Install/Uninstall Addons](https://supertuxkart.net/Installing_Add-Ons)

**Using environment variable**
I provide a script with this docker-container that takes care of downloading all addon tracks when the server starts up. This will take a long time on the first time the server is started up, but afterwards, the tracks are saved in the folder `/path_on/host/stk/addons` 
For this to work:
1) Create a folder .e.g. /path_on/host/stk/addons
2) Mount the folder as shown above in the docker run command
3) Add/Change environment variable  **STK_INSTALL_ADDONS=true**

I also provide a script which can automate the updates of addon tracks.
The script updates tracks by checking for new versions of the addon tracks daily (scheduled at 4:00am in the timezone set via the TZ environment variable.
If automatically downloads new versions of tracks, if a local version is outdated.
For this, just set **STK_UPDATE_ADDONS=true**

### Using a database

Infos on how to 
- Create a database
- Configure additional settings within the server_config.xml
can be found within  [Create Database.md](https://github.com/iluvatyr/docker-supertuxkart/blob/master/Create-Database.md)
The server can then be started as shown in docker-compose.yml or the docker-run example

### Adding AI karts (Computer players)

You can add AI karts to your server by setting the environment variable `STK_AI_KARTS=X`, with X being the number of AI-Karts you would like to add.

Inside the server_config.xml, you can additionally specify if AI_Karts should be added/removed automatically depending on real players connected to the server with the following variable:
<!-- If true this server will auto add / remove AI connected with network-ai=x, which will kick N - 1 bot(s) where N is the number of human players. Only use this for non-GP racing server. -->
`<ai-handling value="true" />`

### Mounting log files:

Make sure to create **server_config.log** and **stdout.log** as empty files on the host fs before starting the container. Then use them as shown in the `docker run` example above so that they can be successfully mounted and written to inside the container. You can then check the logfiles on the host server via those files.

## Some additional infos

### Differences to jwestp image:
This docker-container for SuperTuxKart is fairly advanced and makes it very easy to host a server and configure it to your will.
This docker image uses a modified version of stk-code from [kimden/stk-code](https://github.com/kimden/stk-code) instead of [supertuxkart/stk-code](https://github.com/supertuxkart/stk-code.git) for building the image. This adds a few more functionalities and is fully compatible with the standard stk-code. 

A list of the [changes in kimden/stk-code](https://github.com/kimden/stk-code/blob/master/FORK_CHANGES.md) can be viewed by clicking the link. A lot Supertuxkart-servers run with his stk-code additions. 

### Functions of this Supertuxkart-Server-Docker-Image
- Easy to understand README.md
- The whole supertuxkart-server-process is running as nonroot.
- PGID and PUID of the supertuxkart user can be custom set.
- Support for sqlite3 database server management ( HowTo: [Create-Database.md](https://github.com/iluvatyr/docker-supertuxkart/blob/master/Create-Database.md) )
- Support to configure the server easily through environment variables in docker run or docker-compose. e.g.
    - Automated Addon installation
    - Automated Addon updates via daily cronjob
    - Add AI via environment variable
    - Let supertuxkart-server push to a custom URL to notify that it is running
    - Configure some server_config.xml values through environment variables (PORT,FIREWALLED)
### To be added
- Automated server restarts after updates
- Automated checking if server is online via online.supertuxkart.net api that lists servers and restarting it.
- Let all options in the server_config.xml be changed by environment variables.

### What is SuperTuxKart?

SuperTuxKart (STK) is a free and open-source kart racing game, distributed under the terms of the GNU General Public License, version 3. It features mascots of various open-source projects. SuperTuxKart is cross-platform, running on Linux, macOS, Windows, and Android systems. Version 1.0 was officially released on April 20, 2019.

SuperTuxKart started as a fork of TuxKart, originally developed by Steve and Oliver Baker in 2000. When TuxKart's development ended around March 2004, a fork as SuperTuxKart was conducted by other developers in 2006. SuperTuxKart is under active development by the game's community.

> [wikipedia.org/wiki/SuperTuxKart](https://en.wikipedia.org/wiki/SuperTuxKart)

Another wiki for SuperTuxKart is also provided by [kimden](https://github.com/kimden/) here:
> [Supertuxkart Wiki by Kimden](https://stk.kimden.online/wiki/index.php?title=Main_Page)

For a helpful, but incomplete list of ingame commands (also for server admin), you can refer to following links:
> [Ingame server commands kimden](https://stk.kimden.online/wiki/index.php?title=Frankfurt_servers)
> [Ingame server command iluvatyr](https://stk.iluvatyr.com/commands)
