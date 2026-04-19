#!/bin/bash

ayuda(){
	echo "Usage: $(basename "$0") <IP>"
	echo "DESCRIPTION"
	echo "Programa que hace ping a todos los dispositivos en la red"
	echo "PARAM:"
	echo "IP	Ip de la red terminada en .0 (ej. 192.168.1.0)"
}

# Verificar si se solicitó ayuda o si no hay argumentos
if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
    ayuda
    exit 0
fi

IP="$1"

prefix=${IP%.0}

for ((i=1; i<256; i++)); do
	( 
	if ( ping "${prefix}.$i" -c 1 -W 1 &>/dev/null ); then 
		echo "Host ${prefix}.$i  Activo" >> hostsActivos.txt
	fi 
	) &
	
done
wait
echo "Escaneo finalizado"
