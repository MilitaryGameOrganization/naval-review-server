#!/bin/bash

# the script to remove libraries by mojang

set -e

map_lib_name() {
    case "$1" in
    # com/googlecode/json-simple/json-simple/1.1.1/json-simple-1.1.1.jar
    # commons-lang/commons-lang/2.6/commons-lang-2.6.jar
    # com/typesafe/akka/akka-actor_2.11/2.3.3/akka-actor_2.11-2.3.3.jar
    # com/typesafe/config/1.3.1/config-1.3.1.jar
    # io/netty/netty-all/4.1.24.Final/netty-all-4.1.24.Final.jar
    # jline/jline/2.13/jline-2.13.jar
    # net/java/dev/jna/jna/4.4.0/jna-4.4.0.jar
    # net/md-5/bungeecord-chat/1.12-SNAPSHOT/bungeecord-chat-1.12-SNAPSHOT.jar
    # net/md-5/SpecialSource/1.8.5/SpecialSource-1.8.5.jar
    # net/sf/jopt-simple/jopt-simple/5.0.3/jopt-simple-5.0.3.jar
    # net/sf/trove4j/trove4j/3.0.3/trove4j-3.0.3.jar
    # org/apache/commons/commons-lang3/3.5/commons-lang3-3.5.jar
    # org/apache/logging/log4j/log4j-api/2.17.1/log4j-api-2.17.1.jar
    # org/apache/logging/log4j/log4j-core/2.17.1/log4j-core-2.17.1.jar
    # org/apache/maven/maven-artifact/3.5.3/maven-artifact-3.5.3.jar
    # org/jline/jline/3.5.1/jline-3.5.1.jar
    # org/ow2/asm/asm-debug-all/5.2/asm-debug-all-5.2.jar
    "org/scala-lang/plugins/scala-continuations-library_2.11/1.0.2_mc/scala-continuations-library_2.11-1.0.2_mc.jar")
        echo "org/scala-lang/plugins/scala-continuations-library_2.11/1.0.2/scala-continuations-library_2.11-1.0.2.jar" ;;
    # org/scala-lang/plugins/scala-continuations-library_2.11/1.0.2/scala-continuations-library_2.11-1.0.2.jar
    "org/scala-lang/plugins/scala-continuations-plugin_2.11.1/1.0.2_mc/scala-continuations-plugin_2.11.1-1.0.2_mc.jar")
        echo "org/scala-lang/plugins/scala-continuations-plugin_2.11.1/1.0.2/scala-continuations-plugin_2.11.1-1.0.2.jar" ;;
    # org/scala-lang/scala-actors-migration_2.11/1.1.0/scala-actors-migration_2.11-1.1.0.ja
    # org/scala-lang/scala-compiler/2.11.1/scala-compiler-2.11.1.jar
    # org/scala-lang/scala-library/2.11.1/scala-library-2.11.1.jar
    # forge: org/scala-lang/scala-parser-combinators_2.11/1.0.1/scala-parser-combinators_2.11-1.0.1.jar
    # org/scala-lang/scala-reflect/2.11.1/scala-reflect-2.11.1.jar
    # forge: org/scala-lang/scala-swing_2.11/1.0.1/scala-swing_2.11-1.0.1.jar
    # org/slf4j/slf4j-api/1.7.30/slf4j-api-1.7.30.jar
    # org/slf4j/slf4j-nop/1.7.30/slf4j-nop-1.7.30.jar
    # org/xerial/sqlite-jdbc/3.21.0.1/sqlite-jdbc-3.21.0.1.jar
    # org/yaml/snakeyaml/1.19/snakeyaml-1.19.jar
    *) echo "$1" ;;
    esac
}

get() {
    echo "getting $1" >&2
    curl -sL --fail --retry 5 --retry-delay 1 "$@"
}

# the downloader supports snapshots
download_md5_complex() {
    local group lib var
    read -r group lib ver <<<"$(echo "$1" | perl -pe 's#^(.*/)([^/]+)/([^/]+)/([^/]+)$#\1 \2 \3#')"
    if [[ ! "$ver" = *-SNAPSHOT ]]; then
        return 1
    fi

    simple_var="$(echo "$ver" | perl -pe 's#^(.*)-SNAPSHOT$#\1#')"

    local repo="https://hub.spigotmc.org/nexus/content/repositories/public/"

    XML="$(get "$repo$group$lib/$ver/maven-metadata.xml" | perl -00pe 's/\n| //g' | perl -pe 's#^.*<snapshot>(.*)</snapshot>.*$#\1#')"

    timestamp="$(echo "$XML" | perl -pe 's#^.*<timestamp>(.*)</timestamp>.*$#\1#')"
    buildNumber="$(echo "$XML" | perl -pe 's#^.*<buildNumber>(.*)</buildNumber>.*$#\1#')"

    get "$repo$group$lib/$ver/$lib-$simple_var-$timestamp-$buildNumber.jar.md5"
}

download_md5() {
    local lib="$(map_lib_name "$1")"
    get "https://repo1.maven.org/maven2/$lib.md5" \
        || get "https://hub.spigotmc.org/nexus/content/repositories/public/$lib.md5" \
        || download_md5_complex "$lib" \
        || { get "https://maven.minecraftforge.net/$lib" | compute_md5; }
}

compute_md5() {
    md5sum | perl -pe 's#^(\w+).*$#\1#'
}

find libraries -type f | perl -pe 's#[^/]*/##' | while read line; do
    realsum="$(compute_md5 < "libraries/$line")"
    gotsum="$(download_md5 "$line")"

    if [ "$realsum" != "$gotsum" ]; then
        rm "libraries/$line"
        echo "removed libraries/$line" >&2
    fi
done
