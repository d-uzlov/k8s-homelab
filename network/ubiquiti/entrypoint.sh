#!/bin/bash
set -eu

trap "trap : TERM INT; sleep infinity & wait" TERM INT EXIT

umask 0

# # create our folders
# mkdir -p \
#     /config/{data,logs}

# # create symlinks for config
# symlinks=( \
# /usr/lib/unifi/data \
# /usr/lib/unifi/logs )

# ls -la /config/

# for i in "${symlinks[@]}"; do
#     if [[ -L "$i" && ! "$i" -ef /config/"$(basename "$i")"  ]]; then
#         unlink "$i"
#     fi
#     if [[ ! -L "$i" ]]; then
#         ln -s /config/"$(basename "$i")" "$i"
#     fi
# done

for log_file in migration.log mongod.log server.log
do
    full_path=/usr/lib/unifi/logs/"$log_file"
    rm -f "$full_path"
    mkfifo "$full_path"
    while :; do cat "$full_path" | sed -e 's/^/'"$log_file"': /'; done &
done

if [[ ! -e /usr/lib/unifi/data/system.properties ]]; then
    cp /defaults/system.properties /usr/lib/unifi/data
fi

# Configure memory limits
if grep -q "xmx" /usr/lib/unifi/data/system.properties && grep -q "xms" /usr/lib/unifi/data/system.properties; then
    if [[ $MEM_LIMIT == "default" ]]; then
        echo "*** Setting Java memory limit to default ***"
        sed -i "/unifi.xmx=.*/d" /usr/lib/unifi/data/system.properties
    elif [[ -n $MEM_LIMIT ]]; then
        echo "*** Setting Java memory limit to $MEM_LIMIT ***"
        sed -i "s/unifi.xmx=.*/unifi.xmx=$MEM_LIMIT/" /usr/lib/unifi/data/system.properties 
    fi
    if [[ $MEM_STARTUP == "default" ]]; then
        echo "*** Setting Java memory minimum to default ***"
        sed -i "/unifi.xms=.*/d" /usr/lib/unifi/data/system.properties
    elif [[ -n $MEM_STARTUP ]]; then
        echo "*** Setting Java memory minimum to $MEM_STARTUP ***"
        sed -i "s/unifi.xms=.*/unifi.xms=$MEM_STARTUP/" /usr/lib/unifi/data/system.properties
    fi
elif grep -q "xmx" /usr/lib/unifi/data/system.properties; then
    if [[ $MEM_LIMIT == "default" ]]; then
        echo "*** Setting Java memory limit to default ***"
        sed -i "/unifi.xmx=.*/d" /usr/lib/unifi/data/system.properties
    elif [[ -n $MEM_LIMIT ]]; then
        echo "*** Setting Java memory limit to $MEM_LIMIT ***"
        sed -i "s/unifi.xmx=.*/unifi.xmx=$MEM_LIMIT/" /usr/lib/unifi/data/system.properties
    fi
    if [[ -n $MEM_STARTUP ]]; then
        echo "*** Setting Java memory minimum to $MEM_STARTUP ***"
        echo "unifi.xms=$MEM_STARTUP" >> /usr/lib/unifi/data/system.properties
    fi
elif grep -q "xms" /usr/lib/unifi/data/system.properties; then
    if [[ $MEM_STARTUP == "default" ]]; then
        echo "*** Setting Java memory minimum to default ***"
        sed -i "/unifi.xms=.*/d" /usr/lib/unifi/data/system.properties
    elif [[ -n $MEM_STARTUP ]]; then
        echo "*** Setting Java memory minimum to $MEM_STARTUP ***"
        sed -i "s/unifi.xms=.*/unifi.xms=$MEM_STARTUP/" /usr/lib/unifi/data/system.properties
    fi
    if [[ -n $MEM_LIMIT ]]; then
        echo "*** Setting Java memory limit to $MEM_LIMIT ***"
        echo "unifi.xmx=$MEM_LIMIT" >> /usr/lib/unifi/data/system.properties 
    fi
else
    if [[ -n $MEM_LIMIT ]]; then
        echo "*** Setting Java memory limit to $MEM_LIMIT ***"
        echo "unifi.xmx=$MEM_LIMIT" >> /usr/lib/unifi/data/system.properties 
    fi
    if [[ -n $MEM_STARTUP ]]; then
        echo "*** Setting Java memory minimum to $MEM_STARTUP ***"
        echo "unifi.xms=$MEM_STARTUP" >> /usr/lib/unifi/data/system.properties
    fi
fi

# generate key
if [[ ! -f /usr/lib/unifi/data/keystore ]]; then
    keytool -genkey -keyalg RSA -alias unifi -keystore /usr/lib/unifi/data/keystore \
    -storepass aircontrolenterprise -keypass aircontrolenterprise -validity 3650 \
    -keysize 4096 -dname "cn=unifi" -ext san=dns:unifi
fi

# sleep infinity & wait

exec java \
    -Xms"${MEM_STARTUP}M" \
    -Xmx"${MEM_LIMIT}M" \
    -Dlog4j2.formatMsgNoLookups=true \
    -Dfile.encoding=UTF-8 \
    -Djava.awt.headless=true \
    -Dapple.awt.UIElement=true \
    -XX:+UseParallelGC \
    -XX:+ExitOnOutOfMemoryError \
    -XX:+CrashOnOutOfMemoryError \
    --add-opens java.base/java.lang=ALL-UNNAMED \
    --add-opens java.base/java.time=ALL-UNNAMED \
    --add-opens java.base/sun.security.util=ALL-UNNAMED \
    --add-opens java.base/java.io=ALL-UNNAMED \
    --add-opens java.rmi/sun.rmi.transport=ALL-UNNAMED \
    -jar /usr/lib/unifi/lib/ace.jar start
