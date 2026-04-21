#!/bin/bash

# Uso: ./script.sh https://ejemplo.com lista.txt

web="$1"
dicc="$2"

if [ ! -s "$dicc" ]; then
	echo "Error: El directorio no existe o esta vacio"
	exit 1
fi

#while read espera entrada que luego se le manda con el <
#si lo imaginas como una sola linea tiene mas sentido



while IFS= read -r linea || [ -n "$linea" ] ; do
# -I: obtiene solo las cabeceras (más rápido)
# -s: modo silencioso
# -o /dev/null: No imprime el cuerpo de la respuesta
# -w: imprime el código de estado HTTP
	status=$(curl -Is -o /dev/null -w "%{http_code}" "$web/$linea")
	if [ "$status" -eq 200 ]; then
		echo "[+] Existe: $web/$linea (Codigo: $status)"
	else
		echo "[-] No encontrado: $linea"
	fi
done < "$dicc" #Esto envia lo de dicionario al while
