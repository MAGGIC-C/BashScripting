#!/bin/bash

# Funciones y declaraciones

getUser (){

	read -rp "Nombre del nuevo usuario:" username
	if id "$username" &>/dev/null; then
		echo "Error: El usuario $username ya existe."
		exit 1
	fi
}

getPasswd (){

	while true; do
		#echo -e permite los caracteres de escpae como \n
		echo -e "\nLa contraseña debe cumplir con:"
		echo " - Mínimo 8 caracteres"
		echo " - Al menos una mayúscula"
		echo " - Al menos una minúscula"
		echo " - Al menos un número"
		echo " - Al menos un carácter especial (@, #, $, etc.)"
		    
		read -rsp "Ingrese la contraseña: " password
		echo
		read -rsp "Confirme la contraseña: " password_confirm
		echo

		#Comprobar que las contraseñas sean iguales
		#[[]] son caracteres de evaluacion que permiten comparar las cadenas
		#continue se salta el resto de comandos y vuelve al inicio del bucle
		if [[ "$password" != "$password_confirm" ]]; then
			echo "Las contraseñas no coinciden."
			continue
		fi
		#${#password} le dice a bash que cuente los caracteres
		#-lt (Less than) si son menos que
		if [[ ${#password} -lt 8 ]]; then
			echo "Error: La contraseña debe tener al menos 8 caraacteres"
		#=~ es una expresion condicional para realizar conincidencias de expresiones regulares
		#Permite verificar si una cadena de texto coincide con un patron especifico
		elif [[ ! "$password" =~ [A-Z] ]]; then
			echo "Error: La contraseña debe tener almenos una letra mayuscula"
		elif [[ ! "$password" =~ [a-z] ]]; then
			echo "Error: La contraseña debe tener almenos una letra minuscula"
		elif [[ ! "$password" =~ [0-9] ]]; then
			echo "Error: La contraseña debe tener almenos un numero"
		#[^a-zA-Z0-9] ^ compara con todo lo que no sea una letra o un numero osea un caracter especial
		elif [[ ! "$password" =~ [^a-zA-Z0-9] ]]; then
			echo "Error: La contraseña debe tener almenos un caracter especial"
		else
			break
		fi
	done
}

getGroup (){
    
    echo -e "\nAgregue un grupo al usuario"
    echo "Si el grupo existe el usuario sera agregado al grupo, de otro modo, el grupo sera creado primero"
    read -rp "Ingrese el nombre del grupo " grup
    if ! getent group "$grup"; then
        groupadd "$grup"
    fi

}

askQuota (){
	local resp
	echo -e "\nDesea agregar una cuota al usuario?"
    read -rp "y/n" resp
    case $resp in
        [nN])
            echo "No se agregaran cuotas"
        ;;
        [yY])
            read -rp "Ingrese el limite Soft en KB (102400 para 100MB): " soft
            read -rp "Ingrese el limite Hard en KB (102400 para 100MB): " hard
            read -rp "ingrese el periodo de gracai en (ej 7days o 24hours): " grace

            #Aplicar las cuotas
            #setquota establece limites de forma NO interactiva
            #setquota -u|-g [usuario|grupo] [soft] [hard] [isoft (cantidad de archivos)] [ihard] <sistema de archivos>
            setquota -u "$username" "$soft" "$hard" 0 0 /

            #Aplicar periodo de gracias
            #setquota -t (indica que se va a modificar el tiempo de gracia) -u (especifica que el cambio se aplica a un usuario) <tiempo> [periodo de gracia de archivos 0=default] <donde se aplica la cuota>
            setquota -t -u "$grace" "$grace" /

            echo "Cuotas asignadas con exito"
        ;;
        *)
            echo "Error: opcion no valida"
    esac
    
}

askSudo (){
	local resp
	local opt
	local cmds
    echo -e "\n¿El usuario '$username' tendrá permisos de sudo?"
    read -rp "y/n: " resp
    case $resp in
        [yY])
            echo -e "\nTipos de permisos sudo:"
            echo " 1) Acceso total (Todos los comandos)"
            echo " 2) Comandos específicos"
            read -rp "Seleccione una opción: " opt

            case $opt in
                1)
                    # Crear archivo en sudoers.d para acceso total
                    echo "$username ALL=(ALL:ALL) ALL" > "/etc/sudoers.d/$username"
                    chmod 440 "/etc/sudoers.d/$username"
                    echo "Permisos totales de sudo asignados."
                ;;
                2)
                    read -rp "Ingrese los comandos (separados por coma y ruta completa, ej: /usr/bin/apt, /usr/bin/systemctl): " cmds
                    # Crear archivo con comandos restringidos
                    echo "$username ALL=(ALL:ALL) $cmds" > "/etc/sudoers.d/$username"
                    chmod 440 "/etc/sudoers.d/$username"
                    echo "Permisos limitados asignados exitosamente."
                ;;
                *)
                    echo "Opción no válida. No se asignaron permisos sudo."
                ;;
            esac
        ;;
        *)
            echo "El usuario no tendrá permisos de sudo."
        ;;
    esac
}

#Comprobar permisos de administrador
if [[ $EUID -ne 0 ]]; then
	echo "Este comando debe usarse con permisos de administrador¡¡¡"
	exit 1
fi

#Inicio del Script
getUser
getPasswd
getGroup

#Crea el usuario con directorio home y shell bash
useradd -d /home/"$username" -m -k /etc/skel -s /bin/bash -g "$grup" "$username"

#chpasswd es una herramienta para cambiar contraseñas de usuarios en lote desde la entrada standard
#es mas robusta que passwd "usuario"
echo "$username:$password" | chpasswd

#Configuraciones adicionales
askQuota
askSudo

#yaquedotuuuu
echo -e "\nUsuario $username creado exitosamente"
