#!/bin/bash

ayuda (){

	echo "Script que permite conectar equipo a una red de forma interactiva."
}


interfaz_w="$(basename /sys/class/net/w*)"

mostrar_interfaces(){ ip -br a; }

mostrar_redes(){ iw dev "$interfaz_w" scan | grep SSID; }

levantar(){ ip link set "$interfaz_w" up; }
domir(){ ip link set "$interfaz_w" down; }


echo "$interfaz_w"
mostrar_interfaces
mostrar_redes
