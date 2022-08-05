#!/bin/bash

# shellcheck disable=SC2172

trap '
    echo "server stopping..." >&2;
    {
        /server/rcon-cli --address localhost:25575 --password rcon "say server stopping in 30 seconds";
        sleep 15;
        /server/rcon-cli --address localhost:25575 --password rcon "say server stopping in 15 seconds";
        sleep 10;
        /server/rcon-cli --address localhost:25575 --password rcon "say server stopping in 5 seconds";
        sleep 5;
        /server/rcon-cli --address localhost:25575 --password rcon save-all;
        /server/rcon-cli --address localhost:25575 --password rcon stop
    } || {
        echo "cannot use stop command; fall back to kill command" >&2;
        kill $pid
    };
    wait $pid
' TERM INT

HEAP="${HEAP:-16G}"
PAUSE="${PAUSE:-100}"

mkdir -p /save/world
mkdir -p /save/logs
mkdir -p /save/crash-reports

# download mods
java -jar mod-downloader.jar \
    --force \
    --server \
    --config mods.txt \
    --dest mods \
    || exit 1;

java -Xms"$HEAP" -XX:MetaspaceSize=2048m -XX:MaxMetaspaceSize=2048m \
    -XX:+OptimizeStringConcat -XX:+AggressiveOpts \
    -XX:+UseStringDeduplication -XX:+DisableExplicitGC -XX:+UseBiasedLocking \
    -XX:+UseG1GC -XX:MaxGCPauseMillis="$PAUSE" -XX:ParallelGCThreads=10 \
    -Dfml.queryResult=confirm \
    -verbose:gc -XX:+PrintGCDateStamps \
    -Xloggc:logs/gc-$(date --iso-8601=seconds | sed 's/[-:T+]//g').log \
    -Dlog4j.configurationFile=log4j2.xml\
    -jar mohist.jar nogui \
    < /dev/stdin > /dev/stdout &

pid=$!

wait $pid
