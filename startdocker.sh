#!/bin/bash

parse(){
	msg="- $1 \n - Numero de argumentos invalido"
	msg="$msg \n\n dockerStart [options]"
	msg="$msg \n 	1) -r: run or -i: install"
	msg="$msg \n 	2) -a: all, -s: site, -h: hodeline, -e: secure, -w: webapps"
	msg="\n $msg \n"
	printError "$msg"
}

printError(){
	shopt -s xpg_echo
	echo $1
	exit
}

printWarning(){
	shopt -s xpg_echo
	echo $1
}

printFinalHelp(){
	shopt -s xpg_echo
	printf "${GREEN}"
	hostConfig="docker inspect --format='{{.Name}}  {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $i $containerName"
	echo "\n Sus servidores se crearon con la siguiente configuracion"
	eval $hostConfig

	echo "\nPara ingresar a sus servidores ejecute los siguientes comandos:"
	command="docker inspect --format='{{.Name}}:$ docker exec -it {{.Config.Hostname}} bash' $i $containerName"
	eval $command
	echo "\nLos servidores site y secure cuentan con certificaciones SSL (opcional)\nruta certificados:\n"
	echo "/- SSLCertificateFile /etc/pki/tls/certs/certificate.crt\n/- SSLCertificateKeyFile /etc/pki/tls/private/certificate.key"
	printf "${NC}"
}

# Instala el entorno indicado
installEnviroments(){

	# Validando si es necesario el reinicio del equipo	
	if [ ! -z $REINICIO ] && $REINICIO; then
		printf "${RED}Debe reiniciar el equipo para que tome los cambios necesarios.\nDesea reiniciarlo en este momento [y/n]:${NC}"
		read REINICIOUSER
		if [ !  -z $REINICIOUSER ] && [ "$REINICIOUSER" == "y" ] || [ "$REINICIOUSER" == "Y" ] ; then
			echo "Reiniciando equipo ..."
			reboot
		else
			exit
		fi
	fi

	shopt -s xpg_echo
	# Reiniciamos el servicio docker
	sudo service docker restart

	echo "\nInstalando entornos ..."	
	docker build -t jgomez17/centos-php54-apache -f Dockerfile .

}

stopContainerByName(){
	# Detiene contenedores del site existentes
	echo " \-Parando contenedor ($1)"
	docker stop $(docker inspect --format='{{.Id}}' $i $1)
	echo " \-Eliminando contenedor ($1)"
	docker rm $(docker inspect --format='{{.Id}}' $i $1)
}

# Arranca entornos indicados
runEnviroments(){
	shopt -s xpg_echo
	echo "\nArrancando entornos ..."
	msg="no es un directorio valido! Verifique las rutas en su archivo de configuracion [exit]"
	msgFile="no es un archivo valido! Verifique las rutas en su archivo de configuracion [exit]"
	containerName="sites"
	rutHW=""
	rutSecure=""
	rutSite=""
	rutWebApps=""
	# Detiene contenedores del site existentes
	stopContainerByName $containerName
	
	if [ ! -z $ENVSECURE ] && $ENVSECURE; then
		# Validando el directorio principal
		if [ ! -d $RUTA_SECURE ] || [ -z $RUTA_SECURE ] ; then
			printWarning " \- RUTA_SECURE ($RUTA_SECURE) $msg"
		else
			RUTA_SECURE="-v $RUTA_SECURE:/var/www/html/securewebgds:rw"
		fi
		if [ ! -d $RUTA_AMADEUS ] || [ -z $RUTA_AMADEUS ] ; then
			printWarning " \- RUTA_AMADEUS ($RUTA_AMADEUS) $msg"
		else
			RUTA_AMADEUS="-v $RUTA_AMADEUS:/var/www/html/amadeusdecameron:rw"
		fi
		if [ ! -d $RUTA_PNP ] || [ -z $RUTA_PNP ] ; then
			printWarning " \- RUTA_PNP ($RUTA_PNP) $msg"
		else
			RUTA_PNP="-v $RUTA_PNP:/var/www/html/pnpwebservice:rw"
		fi
		if [ ! -d $RUTA_MDM ] || [ -z $RUTA_MDM ] ; then
			printWarning " \- RUTA_MDM ($RUTA_MDM) $msg"
		else
			RUTA_MDM="-v $RUTA_MDM:/var/www/html/mdmdecameron:rw"
		fi

                rutSecure="$RUTA_SECURE $RUTA_AMADEUS $RUTA_PNP $RUTA_MDM"		
    	fi
	
	if [ ! -z $ENVHODELINE ] && $ENVHODELINE; then                
		if [ ! -d $RUTA_HODELINE ] ; then
			printError "\n\- RUTA_HODELINE ($RUTA_HODELINE) $msg"
		fi

		if [ ! -d $RUTA_TEMPORAL ] ; then
			printError "\n\- ($RUTA_TEMPORAL) $msg"
		fi

                rutHW="-v $RUTA_HODELINE:/var/www/html/decameron:rw -v $RUTA_TEMPORAL:/var/www/temporal:rw"
	fi
        
	if [ ! -z $ENVSITE ] && $ENVSITE; then
                # Validando el directorio principal
		if [ ! -d $RUTA_PARTICULARES ] || [ -z $RUTA_PARTICULARES ] ; then
			printWarning " \- RUTA_PARTICULARES ($RUTA_PARTICULARES) $msg"
		else
			RUTA_PARTICULARES="-v $RUTA_PARTICULARES:/var/www/html/www.decameron.com:rw"
		fi
		if [ ! -d $RUTA_AGENCIAS ] || [ -z $RUTA_AGENCIAS ] ; then
			printWarning " \- RUTA_AGENCIAS ($RUTA_AGENCIAS) $msg"
		else
			RUTA_AGENCIAS="-v $RUTA_AGENCIAS:/var/www/html/promosdecameron:rw"
		fi
		if [ ! -d $RUTA_TEMPORAL ] ; then
			printError "\n\- ($RUTA_TEMPORAL) $msg"
		fi
		
                rutSite="$RUTA_PARTICULARES -v $RUTA_TEMPORAL:/var/www/temporal:rw $RUTA_AGENCIAS"
		
	fi

	command="docker run -dt --name $containerName $rutSecure $rutSite $rutHW -p 80:80 -p 443:443 jgomez17/centos-php54-apache"
	eval $command

	# Se generan Hosts en los container
	command="docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $i $containerName"	
	ipcontainerSite=$(eval $command)
	containerId=$(docker inspect --format='{{.Id}}' $i $containerName)
	service="docker exec -it $containerId /bin/bash -c 'service httpd start'"
	eval $service

	# configuramos virtual hosts en los contenedores como en el host principal
	cantBalancer=$(cat $pathBalancer | jq '. | length')
	COUNTER=0
        while [ $COUNTER -lt $cantBalancer ]; do
		principal=$(cat $pathBalancer | jq ".[$COUNTER] .principal" | sed 's/"//g')
	 	if ! grep -q "\s${principal}$" /etc/hosts ; then 
			sudo -- sh -c "echo '$ipcontainerSite	$principal' >> /etc/hosts"
		else
			# si existe lo modificamos a la nueva ip
			sudo cp /etc/hosts /etc/hosts_bk
			sudo -- sh -c "cat /etc/hosts_bk | sed 's/.*\t$principal/$ipcontainerSite\t$principal/g' > /etc/hosts"
		fi

		hostsSite="docker exec -it $containerId bash -c \"echo '$ipcontainerSite	$principal' >> /etc/hosts\""
		eval $hostsSite

		#agregamos los hosts de los nodos
		cantNodes=$(cat $pathBalancer | jq ".[$COUNTER] .sites | length")
		COUNTERNODE=0
		while [ $COUNTERNODE -lt $cantNodes ] ; do
			let COUNTERNODE=COUNTERNODE+1
			node=$(cat $pathBalancer | jq ".[$COUNTER] .sites .nodo$COUNTERNODE" | sed 's/"//g')
			hostsSite="docker exec -it $containerId bash -c \"echo '$ipcontainerSite	$node' >> /etc/hosts\""
			eval $hostsSite
		done
		let COUNTER=COUNTER+1 
	done
}


if test "$(($#))" -le 0 ; then
	parse
fi

for param in "$@"
do
case $param in
	-i)
		INSTALL=true
	;;
	-r)
		RUN=true
	;;
	-a)
		ENVSITE=true
		ENVHODELINE=true
		ENVSECURE=true
		ENVWEBAPP=true
	;;
	-s)
		ENVSITE=true
	;;
	-h)
		ENVHODELINE=true
	;;
	-e)
		ENVSECURE=true
	;;
	-w)
		ENVWEBAPP=true
	;;
	*)
	;;
esac
done


#Valido que tenga instalado jq para poder procesar la informacion de configuracion
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
if [ -x /usr/bin/jq ] || [ -x /usr/sbin/jq ]; then
	echo "Tienes instalado JQ para archivos json"
else
	echo "Instalado JQ para archivos json..."
	if [ -f /etc/debian_version ]; then
		sudo apt-get install -y jq
	elif [ -f /etc/redhat-release ]; then
		printf "${RED}"
		sudo yum install -y jq
		printf "${NC}"
	fi
fi


#Valido que tenga instalado docker de no ser asi se instalara
if [ -x /usr/bin/docker ] || [ -x /usr/sbin/docker ]; then
	echo "Tienes Docker Instalado..."
else
	echo "Instalando Docker..."
	printf "${RED}"
	curl -sSL https://get.docker.com/ | sh
	printf "${NC}"
	if [ -f /etc/debian_version ]; then
		sudo chkconfig docker on
	elif [ -f /etc/redhat-release ]; then
		sudo systemctl enable docker
	fi
fi

if ! groups | grep -q docker; then
	sudo usermod -a -G docker ${USER}
	REINICIO=true
fi

ps -ef | grep 'docker daemon\|dockerd' | grep -v grep
if [ $?  -eq "0" ] ; then
	echo " \-El proceso esta corriendo" 
else
	echo " \-El proceso no esta corriendo. Intentando iniciar el servicio ..." && service docker start
	ps -ef | grep 'docker daemon\|dockerd' | grep -v grep
	[ $?  -eq "0" ] && echo " \-El proceso esta corriendo" || printError "No fue posible iniciar el servicio. Intentelo nuevamente"
fi

# Valido parametros requeridos
if [ -z $ENVSITE ] && [ -z $ENVHODELINE ] && [ -z $ENVSECURE ] && [ -z $ENVWEBAPP ]; then
        parse "Especifique el entorno a trabajar"
fi

# Valida la ruta del archivo de configuracion
pathBalancer="./configuration/balancer.conf"
pathConfiguration="./configuration/rutas.conf"
if [ ! -f $pathConfiguration ] ; then
	printError "El archivo de configuración no existe! [exit]"
fi

# Obteniendo variables del archivo de configuracion
IFS="="
while read -r name value
do
	var="$name"
	eval "${var}='${value//\"/}'"
done < $pathConfiguration

# Validando opciones enviadas por consola
if [ ! -z $INSTALL ] || [ ! -z $RUN ] ; then
	if [ ! -z $INSTALL ] && $INSTALL ; then
		installEnviroments
	fi

	if [ ! -z $RUN ] && $RUN ; then
		runEnviroments
		printFinalHelp
	fi
fi

