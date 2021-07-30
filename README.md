# Docker SuperTuxKart Server

This is a docker image for deploying a [SuperTuxKart](https://supertuxkart.net) server. It uses a modified version of stk-code from kimden, which can be found [here](https://github.com/kimden/stk-code). It adds a few more functionalities and is fully compatible with the standard stk-code. A lot Supertuxkart-servers run with this server version.

## What is SuperTuxKart?

SuperTuxKart (STK) is a free and open-source kart racing game, distributed under the terms of the GNU General Public License, version 3. It features mascots of various open-source projects. SuperTuxKart is cross-platform, running on Linux, macOS, Windows, and Android systems. Version 1.0 was officially released on April 20, 2019.

SuperTuxKart started as a fork of TuxKart, originally developed by Steve and Oliver Baker in 2000. When TuxKart's development ended around March 2004, a fork as SuperTuxKart was conducted by other developers in 2006. SuperTuxKart is under active development by the game's community.

> [wikipedia.org/wiki/SuperTuxKart](https://en.wikipedia.org/wiki/SuperTuxKart)
> [Supertuxkart Wiki by Kimden](https://stk.kimden.online/wiki/index.php?title=Main_Page)

![logo](https://raw.githubusercontent.com/jwestp/docker-supertuxkart/master/supertuxkart-logo.png)

## How to use this image

The image exposes ports 2759 (server) and 2757 (server discovery), although only udp port 2759 has to be forwarded on the router for players to be able to connect on a public server. The server should be configured using your own server config file. The config file template can be found [here](https://github.com/jwestp/docker-supertuxkart/blob/master/server_config.xml). Modify it according to your needs and mount it at `/stk/server_config.xml`:


### Hosting a public server on the internet (wan-server)

For hosting a server on the internet (by setting `wan-server` to `true` in the config file) it is required to log in with your STK account. You can register a free account [here](https://online.supertuxkart.net/register.php). Pass your username and password to the container via environment variables.

```
docker run --name my-stk-server \
           -d \
           -p 2757:2757 \
           -p 2759:2759 \
           -v $(pwd)/server_config.xml:/stk/server_config.xml \
           -e USERNAME=myusername \
           -e PASSWORD=mypassword \
           -e AI_KARTS=0 \
           jwestp/supertuxkart:latest
```

Make sure that inside stk/server_config.xml  `<wan-server value="true" />` is set

### Hosting a server in your local network

You can use the same docker run as above without providing the USERNAME and PASSWORD environment variables.

### Adding ai karts

You can add ai karts to your server by setting the environment variable `AI_KARTS=X`, with X being the number of AI-Karts you would like to add.
Inside the server_config.xml, you can additionally specify if AI_Karts should be added/removed automatically depending on real players connected to the server with the following variable:
<!-- If true this server will auto add / remove AI connected with network-ai=x, which will kick N - 1 bot(s) where N is the number of human players. Only use this for non-GP racing server. -->
`<ai-handling value="true" />`

### Accessing the network console

You can access the interactive network console with the following command:

```
docker exec -it my-stk-server supertuxkart --connect-now=127.0.0.1:2759 --network-console
```

If your server is password secured use the following command:

```
docker exec -it my-stk-server supertuxkart --connect-now=127.0.0.1:2759 --server-password=MY_SERVER_PASSWORD --network-console
```

### Using docker-compose

Clone this repository and have a look into the `docker-compose.yml` to edit your credentials (username & password). If you want to run a public server without needing a password, you can remove the `environment` section with its corresponding entries.
After editing, you can get the server up and running by doing a `docker-compose up -d`. Have a look at the logs by using `docker-compose logs` This can be especially useful when searching for bugs.
