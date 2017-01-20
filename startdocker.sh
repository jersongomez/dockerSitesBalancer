#!/bin/bash

parse(){
	msg="- $1 \n - Numero de argumentos invalido"
	msg="$msg \n\n dockerStart [options]"
	msg="$msg \n   -r: run or -i: install"
	msg="\n $msg \n"
	printError "$msg"
}

detectPlatform(){
	PLATFORM_DETECTED=$(uname)
	PLATFORM="linux"
	if ! uname | grep -i linux; then
		PLATFORM="windows"
	fi
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
	if [ $PLATFORM = "linux" ]; then
		hostConfig="docker inspect --format='{{.Name}}  {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $i $containerName"
	else
		hostName="docker inspect --format='{{.Name}}' $i $containerName"
		hostConfig="$hostName && docker-machine ip default"
	fi
	
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
	#sudo service docker restart

	echo "\nInstalando entornos ..."	
	docker build -t jgomez17/centos-php54-apache -f sites/Dockerfile .

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

	# Detiene contenedores del site existentes
	stopContainerByName $containerName
	RUTA_WWW="-v $RUTA_WWW:/var/www/:rw"
	command="docker run -dt --name $containerName $RUTA_WWW -p 80:80 -p 443:443 jgomez17/centos-php54-apache"
	eval $command

	# Se generan Hosts en los container
	if [ $PLATFORM = "linux" ]; then
		command="docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $i $containerName"	
		ipcontainerSite=$(eval $command)
		jq="jq"
	else
		ipcontainerSite=$(docker-machine ip default)
		jq="/c/cygwin/bin/jq.exe"
	fi

	containerId=$(docker inspect --format='{{.Id}}' $i $containerName)
	service="docker exec -it $containerId /bin/bash -c 'service httpd start'"
	eval $service

	# configuramos virtual hosts en los contenedores como en el host principal
	cantBalancer=$(cat $pathBalancer | $jq '. | length')
	COUNTER=0
    while [ $COUNTER -lt $cantBalancer ]; do
		principal=$(cat $pathBalancer | $jq ".[$COUNTER] .principal" | sed 's/"//g')
		hostPath="/etc/hosts"
		hostPathBk="/tmp/hosts_bkp"
		
		if [ $PLATFORM = "windows" ];then
			hostPath="/c/Windows/System32/drivers/etc/hosts"
		fi
		
	 	if ! grep -q "\s${principal}$" $hostPath ; then 
			sh -c "echo '$ipcontainerSite	$principal' >> $hostPath"
		else
			# si existe lo modificamos a la nueva ip
			cp $hostPath $hostPathBk
			sh -c "cat $hostPathBk | sed 's/.*\t$principal/$ipcontainerSite\t$principal/g' > $hostPath"
		fi

		hostsSite="docker exec -it $containerId bash -c \"echo '$ipcontainerSite	$principal' >> /etc/hosts\""
		eval $hostsSite

		#agregamos los hosts de los nodos
		cantNodes=$(cat $pathBalancer | $jq ".[$COUNTER] .sites | length")
		COUNTERNODE=0
		while [ $COUNTERNODE -lt $cantNodes ] ; do
			let COUNTERNODE=COUNTERNODE+1
			node=$(cat $pathBalancer | $jq ".[$COUNTER] .sites .nodo$COUNTERNODE" | sed 's/"//g')
			hostsSite="docker exec -it $containerId bash -c \"echo '$ipcontainerSite	$node' >> $hostPathBk\""
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
	*)
	;;
esac
done


#Valido que tenga instalado jq para poder procesar la informacion de configuracion
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

detectPlatform

if [ $PLATFORM = "linux" ]; then
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
fi


# Valida la ruta del archivo de configuracion
pathBalancer="./sites/configuration/balancer.conf"
pathConfiguration="./sites/configuration/rutas.conf"

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

