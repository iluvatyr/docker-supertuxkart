# Docker SuperTuxKart Server & difference to jwestp image:

This is a docker image for deploying a [SuperTuxKart](https://supertuxkart.net) server. It uses a modified version of stk-code from [kimden/stk-code](https://github.com/kimden/stk-code) instead of [supertuxkart/stk-code](https://github.com/supertuxkart/stk-code.git) for building the image. This adds a few more functionalities and is fully compatible with the standard stk-code. A lot Supertuxkart-servers run with this server version. Most prominent changes here are:

1) Support for sqlite3 database server management (turn on in server_config.xml, description how to set up the database in [Create-Database.md](https://github.com/iluvatyr/docker-supertuxkart/blob/master/Create-Database.md)
2) Support for setting up the timezone with the Environment variable, e.g. TZ=Europe/London (otherwise logs show wrong time)
3) Using kimdens modified stk-code for additional functions, such as having server records stored in database or gnu elimination mode etc. More infos about that on [kimden/stk-code](https://github.com/kimden/stk-code)
4) Documentation a little more "newbie-friendly"

## What is SuperTuxKart?

SuperTuxKart (STK) is a free and open-source kart racing game, distributed under the terms of the GNU General Public License, version 3. It features mascots of various open-source projects. SuperTuxKart is cross-platform, running on Linux, macOS, Windows, and Android systems. Version 1.0 was officially released on April 20, 2019.

SuperTuxKart started as a fork of TuxKart, originally developed by Steve and Oliver Baker in 2000. When TuxKart's development ended around March 2004, a fork as SuperTuxKart was conducted by other developers in 2006. SuperTuxKart is under active development by the game's community.

> [wikipedia.org/wiki/SuperTuxKart](https://en.wikipedia.org/wiki/SuperTuxKart)

Another wiki for SuperTuxKart is also provided by [kimden](https://github.com/kimden/) here:
> [Supertuxkart Wiki by Kimden](https://stk.kimden.online/wiki/index.php?title=Main_Page)

For a helpful, but incomplete list of commands you can use as a server admin ingame, you can refer to his wiki page here:
> [Ingame server commands](https://stk.kimden.online/wiki/index.php?title=Frankfurt_servers)

![logo](https://raw.githubusercontent.com/jwestp/docker-supertuxkart/master/supertuxkart-logo.png)

## How to use this image

The image exposes ports 2759 (server) and 2757 (server discovery), although only udp port 2759 has to be forwarded on the router for players to be able to connect on a public server. The server should be configured using your own server config file. The config file template can be found [here](https://github.com/iluvatyr/docker-supertuxkart/blob/master/server_config.xml). Modify it according to your needs and mount it at `/stk/server_config.xml`:


### Hosting a public server on the internet (wan-server)

For hosting a server on the internet (by setting `wan-server` to `true` in the config file) it is required to log in with your STK account. You can register a free account [here](https://online.supertuxkart.net/register.php). Pass your username and password to the container via environment variables. Also make sure to change the volume paths on the host for the configuration data. Delete all lines specifying #optional if not needed.

Minimal docker run:


```
docker run --name my-stk-server \
           -d \
           -p 2757:2757 \
           -p 2759:2759 \
           -v $(pwd)/path_on_host/STK/server_config.xml:/stk/server_config.xml \
           -e USERNAME=myusername \ #remove if only LAN-server
           -e PASSWORD=mypassword \ #remove if only LAN-server
           iluvatyr/supertuxkart:latest
```

Full docker run:
```
docker run --name my-stk-server \
           -d \
           -p 2757:2757 \
           -p 2759:2759 \
           -v $(pwd)/path_on_host/STK/server_config.xml:/stk/server_config.xml \
           -v $(pwd)/path_on_host/STK/motd.txt:/stk/motd.txt \ #optional for supplying ingame message of the day
           -v $(pwd)/path_on_host/STK/help.txt:/stk/help.txt \ #optional for when ingame /help command is used
           -v $(pwd)/path_on_host/STK/addons/:/root/.local/share/supertuxkart/addons/ \ #optional for adding addon tracks and karts into the folder.
           -v $(pwd)/path_on_host/STK/replay/:/root/.local/share/supertuxkart/replay/ \ #optional 
           -v $(pwd)/path_on_host/STK/grandprix/:/root/.local/share/supertuxkart/grandprix/ \ #optional 
           -v $(pwd)/path_on_host/STK/screenshots/:/root/.local/share/supertuxkart/screenshots/ \ #optional
           -e USERNAME=myusername \
           -e PASSWORD=mypassword \
           -e AI_KARTS=0 \
           iluvatyr/supertuxkart:latest
```

Make sure that inside stk/server_config.xml  `<wan-server value="true" />` is set as you see here.

### Hosting a server in your local network

You can use the same docker run as above without providing the USERNAME and PASSWORD environment variables for only local access.
Make sure that inside stk/server_config.xml  `<wan-server value="false" />` is set as you see here.

### Adding ai karts

You can add ai karts to your server by setting the environment variable `AI_KARTS=X`, with X being the number of AI-Karts you would like to add.

Inside the server_config.xml, you can additionally specify if AI_Karts should be added/removed automatically depending on real players connected to the server with the following variable:
<!-- If true this server will auto add / remove AI connected with network-ai=x, which will kick N - 1 bot(s) where N is the number of human players. Only use this for non-GP racing server. -->
`<ai-handling value="true" />`

### Seeing log files:

You can see the live output of /root/.config/supertuxkart/config-0.10/stdout.log via following command:

```
docker logs -f my-stk-server
```

More detailed logs are written to /root/.config/supertuxkart/config-0.10/server_config.log inside the container.
These can can optionally mounted on the host for easy access by adding this to the docker run command above:
```
           -v $(pwd)/path_on_host/STK/logs/stdout.log:/root/.config/supertuxkart/config-0.10/stdout.log \ #optional
           -v $(pwd)/path_on_host/STK/logs/server_config.log:/root/.config/supertuxkart/config-0.10/server_config.log \ #optional
```
Make sure to create some empty file with the names on the host already because otherwise it will create a folder there on container startup.
Then they can easily be read with the editor of choice.

### Adding addon tracks

Simply copy the addon tracks folder into into the addons/tracks/ that is mounted as seen in the docker run command. Those maps can for example be downloaded ingame and then copied into the addons/tracks folder. More info on [Install/Uninstall Addons](https://supertuxkart.net/Installing_Add-Ons)

### Accessing the network console

If network-console is set to true in server_config.xml,you can access the interactive network console with the following command:

```
docker exec -it my-stk-server supertuxkart --connect-now=127.0.0.1:2759 --network-console
```

If your server is password secured use the following command:

```
docker exec -it my-stk-server supertuxkart --connect-now=127.0.0.1:2759 --server-password=MY_SERVER_PASSWORD --network-console
```

### Using docker-compose

Clone this repository and have a look into the `docker-compose.yml` to edit your credentials (username & password) and paths to volumes. Delete all optional volumes if not used. After editing, you can get the server up and running by doing a `docker-compose up -d`. Have a look at the logs by using `docker-compose logs` This can be especially useful when searching for bugs.
