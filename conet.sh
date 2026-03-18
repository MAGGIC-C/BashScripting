#!/bin/bash

# Zona de Funciones y Declaraciones-----------------------------
comprobarsudo () {
	if [[ $EUID -ne 0 ]]; then
	   echo "Este comando debe usarse con permisos de administrador¡¡¡"
	   exit 1
	fi
}

mostrar_interfaces(){ ip -br a | awk '$1 != "lo"'; }
mostrar_redes(){ sudo iw dev "$1" scan | grep SSID; }
levantar(){
rfkill unblock wifi
ip link set "$1" up;
 }
domir(){ ip link set "$1" down; }

obtener_dhcp() {
    local iface=$1
    if command -v dhclient &> /dev/null; then
        sudo dhclient "$iface"
    elif command -v dhcpcd &> /dev/null; then
        sudo dhcpcd "$iface"
    elif command -v udhcpc &> /dev/null; then
        sudo udhcpc -i "$iface"
    else
        echo "Error: No se encontró un cliente DHCP (instale dhclient o dhcpcd)."
    fi
}

hacer_permanente() {
    local iface=$1
    local modo=$2
    local ip=$3
    local gw=$4

    echo "Guardando configuración en /etc/network/interfaces..."
    
    # Persistencia de Wi-Fi
    if [ -f "/tmp/wpa_config.conf" ]; then
        sudo mkdir -p /etc/wpa_supplicant
        sudo cp /tmp/wpa_config.conf /etc/wpa_supplicant/wpa_supplicant.conf
        sudo chmod 600 /etc/wpa_supplicant/wpa_supplicant.conf
    fi

    # Escritura del archivo de interfaces
    {
        echo -e "# Generado por CoNet\nauto lo\niface lo inet loopback\n"
        echo "auto $iface"
        echo "iface $iface inet $modo"
        if [ "$modo" == "static" ]; then
            echo "    address ${ip%/*}"
            echo "    netmask 255.255.255.0"
            echo "    gateway $gw"
        fi
        [[ -d "/sys/class/net/$iface/wireless" ]] && echo "    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf"
    } | sudo tee /etc/network/interfaces > /dev/null

    # DNS
    echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" | sudo tee /etc/resolv.conf > /dev/null
    echo "¡Configuración guardada exitosamente!"
}

OPTIONS=("Mostrar interfaces" "Cambiar estado de interfaz" "Conectar a una red" "Salir")
PS3="CoNet Interface Manager: "


#Inicio del Script ---------------------------------------
clear
echo "--- CoNet Interface Manager ---"

comprobarsudo;

#"${OPTIONS[@]}" expansión de Array para que se tome cada frase como un elemento unico del menu
select opt in "${OPTIONS[@]}"; do

#Verificaar que la opcion no sea nula
	if [ -z "$opt" ]; then
		echo "Opcion no Valida. Intente de nuevo."
		continue
	fi

# Limpiar antes de mostrar la selección
	clear
    echo "Ejecutando: $opt"
    echo "-----------------------------------------------"

# crea un array con los nombres de las interfaces
nombres=($(ip -br a | awk '$1 != "lo" {print $1}'))

	case $opt in
		"Mostrar interfaces")
			mostrar_interfaces;
			;;
		"Cambiar estado de interfaz")
			echo "Seleccione una interfaz"
			
			select subopt in "${nombres[@]}" "Atras"; do
				case $subopt in
				"Atras")
					echo "Regresando..."
					break
					;;
				"")
					echo "Opcion no valida. Eliga un numero del menu."
					;;
				*)
					#Captura cualquier nombre de interfaz valido.
					echo "Has seleccionado: $subopt"
					echo "Que accion deseas realizar"
					echo "1) Up" 
					echo "2) Down"
					echo "3) Atras"
					read -rp "Seleccion: " act 
				#Submenu para up/down
				case $act in
					"Up" | "1")
						echo "Levantando $subopt"
						levantar "$subopt"
						break 
						;;
					"Down" | "2")
						echo "Mandando a $subopt a domir con los peces"
						domir "$subopt"
						break 
						;;
					"Atras" | "3")
						break
						;;
					*)
						echo "Respuesta no valida..."
						;;
					esac
					;;
				esac
			done
			;;
		"Conectar a una red")
			echo "Seleccione una interfaz"
			
			select subopt in "${nombres[@]}" "Atras"; do
				case $subopt in
				"Atras")
					echo "Regresando..."
					break
					;;
				"")
					echo "Opcion no valida. Eliga un numero del menu."
					;;
				*)
					#Captura cualquier nombre de interfaz valido.
					if iw dev "$subopt" info >/dev/null 2>&1; then
					    echo "$subopt es Wi-Fi"
					    echo "Seleccione una red para conectarse: "
					    # Guardar cada línea de la salida en un elemento del arreglo redes
						mapfile -t redes < <(sudo iw dev "$subopt" scan | grep -a "SSID: " | sed 's/.*SSID: //' | tr -d '\r' | grep -v '^\s*$' | sort -u)
					    echo "Se han detectado ${#redes[@]} redes disponibles."
					   select ssid in "${redes[@]}" "Atras"; do
					   		case $ssid in
					   			"Atras")
					   				break
					   				;;
					   			"")
					   				echo "Opcion no valida."
					   				;;
					   			*)
					   				echo "Seleccionada red: $ssid"
					   				read -r -s -p "Introduce la contraseña para $ssid: " password
					   				echo ""
					   				# Crea un archivo de configuracion temporal con la clave cifrada
					   				wpa_passphrase "$ssid" "$password" > /tmp/wpa_config.conf

					   				# Matar procesos conflictivos
					   				killall wpa_supplicant 2>/dev/null
					   				
					   				# Iniciar conexion flags: -B (segundo plano), -i (interfaz), -c (archivo de configuración)
					   				sudo wpa_supplicant -B -i "$subopt" -c /tmp/wpa_config.conf

					   				echo "Opciones de conexión: "
					   				echo "1) Estatica"
					   				echo "2) Dinámica"
					   				echo "3) Volver"
					   				read -r selec

					   				case $selec in
					   				 "1" | "Estatica")
					   				 	echo "Asignacion de Ip estatica"
					   				 	read -r -p "Introduzca la IP deseada y la mascara de subred (ej 192.168.0.50/24): " ip_estatica
					   				 	read -r -p "Introduzca el Gateway: " gateway
					   				 	echo "Asisgnando ip estatica en $subopt"
					   				 	#Limpiar ips previas
					   				 	ip addr flush dev "$subopt"
					   				 	
					   				 	ip addr add "$ip_estatica" dev "$subopt"

					   				 	#Agregar gateway
					   				 	ip route add default via "$gateway"

					   				 	echo "Configuracion aplicada."

					   				 	# ... después de agregar el gateway ...
					   				 	echo "Configuracion aplicada."
					   				 	read -r -p "¿Deseas hacerla permanente? (s/n): " confirm
					   				 	[[ "$confirm" == "s" ]] && hacer_permanente "$subopt" "static" "$ip_estatica" "$gateway"
					   				 	break
					   				 	break
					   				 	;;
					   				 "2" | "Dinamica")
					   				 	echo "Solicitando Ip vía DHCP"
					   				 	obtener_dhcp "$subopt"

					   				 	# ... después de llamar a obtener_dhcp ...
					   				 	echo "Configuracion aplicada."
					   				 	read -r -p "¿Deseas hacerla permanente? (s/n): " confirm
					   				 	[[ "$confirm" == "s" ]] && hacer_permanente "$subopt" "dhcp"
					   				 	break
					   				 	break
					   				 	;;
					   				 "3" | "Volver")
					   				 	echo "Regresando..."
					   				 	break
					   				 	;;
					   				 *)
					   				 	echo "Opcion no valida."
					   				 	;;
					   				 esac
					   		esac
					   done 
					else
					    echo "$subopt es Ethernet"
					    echo "Opciones de conexión: "
					    echo "1) Estatica"
					    echo "2) Dinámica"
					    echo "3) Volver"
					    read -r selec

					    case $selec in
					     "1" | "Estatica")
					     	echo "Asignacion de Ip estatica"
					     	read -r -p "Introduzca la IP deseada y la mascara de subred (ej 192.168.0.50/24): " ip_estatica
					     	read -r -p "Introduzca el Gateway: " gateway
					     	echo "Asisgnando ip estatica en $subopt"
					     	#Limpiar ips previas
					     	ip addr flush dev "$subopt"
					     	
					     	ip addr add "$ip_estatica" dev "$subopt"

					     	#Agregar gateway
					     	ip route add default via "$gateway"

					     	echo "Configuracion aplicada."

					     	# ... después de agregar el gateway ...
					     	echo "Configuracion aplicada."
					     	read -r -p "¿Deseas hacerla permanente? (s/n): " confirm
					     	[[ "$confirm" == "s" ]] && hacer_permanente "$subopt" "static" "$ip_estatica" "$gateway"
					     	break
					     	break
					     	;;
					     "2" | "Dinamica")
					     	echo "Solicitando Ip vía DHCP"
					     	obtener_dhcp "$subopt"

					     	# ... después de llamar a obtener_dhcp ...
					     	echo "Configuracion aplicada."
					     	read -r -p "¿Deseas hacerla permanente? (s/n): " confirm
					     	[[ "$confirm" == "s" ]] && hacer_permanente "$subopt" "dhcp"
					     	break
					     	break
					     	;;
					     "3" | "Volver")
					     	echo "Regresando..."
					     	break
					     	;;
					     *)
					     	echo "Opcion no valida."
					     	;;
					     esac
					fi
				esac
			done
			;;
		"Salir")
			echo "Saliendo..."
			break
			;;
		*)
			echo "Opcion no valida: $REPLY"
			;;

	esac

# Pausa para que el usuario vea el resultado antes de volver al menú
    echo ""
# read flags: -n1 (solo un caracter) -s (silencioso no muestra caracter) -r  (raw no interpreta \ como escape) -p promt (permite escribir un mensaje en la misma linea
    read -n 1 -s -r -p "Presione cualquier tecla para volver al menú..."
    clear
    echo "--- CoNet Interface Manager ---"
    
# Esto fuerza a que el menú se vuelva a imprimir
    REPLY=
done

