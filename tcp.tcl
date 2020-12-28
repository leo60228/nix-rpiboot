bindto 0.0.0.0; # 127.0.0.1 doesn't exist
source [find interface/raspberrypi-native.cfg]

set server [socket stream.server 7777]
$server readable {
    set client [$server accept]
    set buf [$client read]
    eval $buf
    $client close
    set done yes
}
echo "Waiting for configuration on port 7777..."
vwait done
$server close
