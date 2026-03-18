#!/bin/bash

comprobarsudo () {
	if [[ $EUID -ne 0 ]]; then
	   echo "Este comando debe usarse con permisos de administrador¡¡¡"
	   exit 1
	fi
}


