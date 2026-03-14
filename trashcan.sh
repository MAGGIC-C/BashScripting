#!/bin/bash

ayuda() {
	echo "Modo de Empleo: $(basename $0) [OPCION] [ARCHIVO]"
    echo "El script ""borra"" un archivo enviandolo a una carpeta de papelera oculta para poderlo recuperar"
	echo "Flags:"
	echo "	-d [delte] envia el archivo a la papelera"
	echo "	-r [restore] restaura el archivo a la ruta actual"
    echo "Parámetros:"
    echo "   Archivo: es el archivo a borrar o recupear"
}


DIR="/tmp/.trashcan"
FILE="$2"
OPT="$1"

comprobar_carpeta(){
#Comprueba la existencia de la carpeta, si no existe, la crea en el directorio tmp
	if [ ! -d "$DIR" ]; then
		mkdir -p "$DIR"
	fi
}

comprobar_archivo(){
#Comprueba que el archivo exista.

	if [ ! -f "$1" ]; then
		echo "Archivo $1 no encontrado"
		exit 1;
	fi
}


case "$OPT" in
	"-d"|"--delete")
		comprobar_carpeta
		comprobar_archivo "$FILE"
		echo "Borrando archivo: $FILE"
		mv "$FILE" "$DIR"
		;;
	"-r"|"--restore")
		comprobar_carpeta
		comprobar_archivo "$DIR/$FILE"
		echo "Recuperando archivo: $FILE"
		mv "$DIR/$FILE" .
		;;
	"-h"|"--help")
		ayuda
		;;
	*)
		echo "Error: Opcion no valida."
		echo "Modo de Empleo: $(basename $0) [OPCION] [ARCHIVO]"
		;;
esac
