#!/bin/bash
DIR="/root/cssv34/csds-v34-2009-08-26"
cd "$DIR"
export LD_PRELOAD='/root/cssv34/nosteam_shim.so /root/cssv34/memfix.so'
export LD_LIBRARY_PATH="$DIR:$DIR/bin:$DIR/platform/bin:$LD_LIBRARY_PATH"
./srcds_i486 -game cstrike -console -usercon -nobreakpad -insecure +ip 0.0.0.0 +port 27015 +maxplayers 16 +map de_dust2
