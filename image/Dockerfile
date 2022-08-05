# syntax = docker/dockerfile:1

ARG MOHIST_VERSION=46
ARG DOWNLOADER_VERSION=0.0.13
ARG CLOSER_VERSION=1.2
ARG RCON_CLI_VERSION=0.10.1

FROM eclipse-temurin:8-jdk as downloader

COPY mods.txt .

ARG DOWNLOADER_VERSION
ARG RCON_CLI_VERSION

RUN curl -L "https://github.com/anatawa12/mod-downloader/releases/download/v${DOWNLOADER_VERSION}/mod-downloader-${DOWNLOADER_VERSION}.jar" > mod-downloader.jar
RUN curl -L "https://github.com/gorcon/rcon-cli/releases/download/v${RCON_CLI_VERSION}/rcon-${RCON_CLI_VERSION}-amd64_linux.tar.gz" \
  | tar -zx -O "rcon-${RCON_CLI_VERSION}-amd64_linux/rcon" > /rcon-cli \
  && chmod +x /rcon-cli

FROM eclipse-temurin:8-jdk as library-downloader

WORKDIR /server

COPY server.properties /server/server.properties
COPY log4j2.xml /server/log4j2.xml
COPY delete-libraries.sh /server/delete-libraries.sh

ARG MOHIST_VERSION
ARG CLOSER_VERSION

RUN curl -L "https://mohistmc.com/builds/1.7.10/Mohist-1.7.10-$MOHIST_VERSION-server.jar" \
    > mohist.jar \
  && mkdir mods \
  && curl -L "https://github.com/anatawa12/minecraft-server-auto-closer/releases/download/$CLOSER_VERSION/minecraft-server-auto-closer-$CLOSER_VERSION.jar" \
    > mods/auto-closer.jar \
  && mkdir config \
  && echo "before world" > config/minecraft-server-auto-closer.txt \
  && echo "eula=true" > eula.txt \
  && timeout 600s java -Xmx2G -jar mohist.jar \
  && bash delete-libraries.sh \
  && rm mods/auto-closer.jar

FROM bash as config-gen

COPY ops.json.sh /ops.json.sh
RUN /ops.json.sh

COPY whitelist.json.sh /whitelist.json.sh
RUN /whitelist.json.sh

FROM alpine as bundler

WORKDIR /server

COPY --from=library-downloader /server/banned-ips.json     /server/banned-ips.json
COPY --from=library-downloader /server/banned-players.json /server/banned-players.json
#COPY --from=library-downloader /server/bukkit.yml          /server/bukkit.yml
#COPY --from=library-downloader /server/cache               /server/cache
#COPY --from=library-downloader /server/commands.yml        /server/commands.yml
COPY --from=library-downloader /server/config              /server/config
COPY --from=library-downloader /server/eula.txt            /server/eula.txt
#COPY --from=library-downloader /server/help.yml            /server/help.yml
COPY --from=library-downloader /server/libraries           /server/libraries
COPY --from=library-downloader /server/log4j2.xml           /server/log4j2.xml
#COPY --from=library-downloader /server/logs                /server/logs
#COPY --from=mods-downloader    /mods                       /server/mods
COPY --from=library-downloader /server/mohist-config       /server/mohist-config
COPY --from=library-downloader /server/mohist.jar          /server/mohist.jar
#COPY --from=library-downloader /server/ops.json            /server/ops.json
#COPY --from=library-downloader /server/paper.yml           /server/paper.yml
#COPY --from=library-downloader /server/permissions.yml     /server/permissions.yml
COPY --from=library-downloader /server/plugins             /server/plugins
COPY --from=library-downloader /server/server.properties   /server/server.properties
#COPY --from=library-downloader /server/snapshots-server    /server/snapshots-server
#COPY --from=library-downloader /server/spigot.yml          /server/spigot.yml
#COPY --from=library-downloader /server/usercache.json      /server/usercache.json
#COPY --from=library-downloader /server/whitelist.json      /server/whitelist.json

# tools
COPY --from=downloader         /mod-downloader.jar         /server/mod-downloader.jar
COPY --from=downloader         /rcon-cli                   /server/rcon-cli
COPY                           mods.txt                    /server/mods.txt

# override configs

COPY --from=config-gen /ops.json          /server/ops.json
COPY --from=config-gen /whitelist.json    /server/whitelist.json

FROM eclipse-temurin:8-jdk

WORKDIR /server

COPY --from=bundler /server /server

# server starter
COPY run.sh /server/run.sh

# create directory for save
RUN ln -s /save/world /server/world \
    && ln -s /save/logs /server/logs \
    && ln -s /save/crash-reports /server/crash-reports

CMD ["/server/run.sh"]
