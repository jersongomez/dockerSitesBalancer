# Contenedores Docker 
Éste script permite de forma fácil configurar los ambientes requeridos para el desarrollo a partir de sencillos archivos de configuración "dominio, virtualhost, sql". haciendo uso de contenedores docker con posibilidad de balancear los site para el trafico de carga.

### Entornos
Existen dos tipos de entornos que se configuran con el script: 
1. Entorno sites. Inicia todos los entornos especificados en el archivo **balancer.conf** teniendo en cuenta los vhosts **httpd-vhosts-***
2. Entorno persistence. Inicia un contenedor adicional que contiene postgres y mysql.

### Configuración
Antes de empezar con la instalación de nuestros entornos debemos configurar de manera correcta los siguentes archivos:

#### Entorno sites "_/sites_"
* **_configuration/balancer.conf_** : Archivo el cual contiene una estructura JSON con el fin de detectar si desea apps balanceados, este archivo debe contener todos los hosts para la configuración correcta del archivo `/etc/hosts` tanto en nuestra máquina local, como en los entornos docker.
* **_configuration/httpd-vhosts-hw.conf_** : Configuración de virtualhost balanceado de hodeline.
* **_configuration/httpd-vhosts-secure.conf_** : Configuración de virtualhost de secure.
* **_configuration/httpd-vhosts-sites.conf_** : Configuración de virtualhost del site.
* **_configuration/httpd-vhosts-webapps.conf_** : Configuración de vistualhost para entornos adicionales.
* **_configuration/rutas.conf_** : Indica la ruta en la que se encuentra alojado localmente el directorio `www` para que sea mapeado en el contenedor docker en la ruta `/var/www/html/`


* **_scripts_** : La carpeta contiene los siguientes archivos:
    * Certificados SSL
        * certificate.crt
        * certificate.csr
        * certificate.key
        
    * Scripts
        *  createBalancer.php : Archivo que nos ayudara con la creacion de los Virtualhost Balancer.
    
    * Llave publica y privada 
        * securep.decameron.com.crt
        * securep.decameron.com.key

#### Entorno persistence "_/sites_"

### Instalación
Se cuenta con un archivo `startdocker.sh`, el cual nos dará la facilidad que sin conocer docker y sus comandos podamos de manera muy facil correr un contenedor con las siguientes especificaciones, ademas de configurarnos los hosts tanto en nuestro container como en nuestro equipo local de tal manera que no debamos preocuparnos por dichas configuraciones:

* _PHP 5.4.40 (built: Aug 30 2016)_
* _Apache/2.2.15 (Unix)_
* _Centos 6_

El archivo `.sh` cuenta con los siguientes procesos:
* Instalación de docker
* Instalación de comando JQ
* Subir servicio docker si este esta inactivo
* Correr contenedor docker 

> `JQ`: Comando para procesar estructuras json

Ejecución `.sh` para la instalación del contenedor.
```sh
$ chmod +x startdocker.sh
$ ./startdocker.sh -i 
```

Si ya cuenta con la instalación de la imagen y solo desea correr el contenedor ejecutar:
```sh
$ ./startdocker.sh -r 
# Este nos arrojara información para el ingreso al contenedor y certificados SSl
Sus servidores se crearon con la siguiente configuracion
/sites  172.17.0.2

Para ingresar a sus servidores ejecute los siguientes comandos:
/sites:$ docker exec -it fce85a4669e5 bash

Los servidores site y secure cuentan con certificaciones SSL (opcional)
ruta certificados:

/- SSLCertificateFile /etc/pki/tls/certs/certificate.crt
/- SSLCertificateKeyFile /etc/pki/tls/private/certificate.key
```
Comandos docker para creación y ejecución del container de forma manual si no desea utilizar el archivo `.sh`, teniendo en cuenta que debera añadir la ip y el host_name de manera manual al archivo `/etc/hosts`.

```sh
# Creacion de imagen 
$ docker build -t jgomez17/centos-php54-apache -f Dockerfile .
# Ejecutar contenedor
$ docker run -dt --name containerName -v $RUTA_LOCAL:$RUTA_CONTAINER:rw -p 80:80 -p 443:443 jgomez17/centos-php54-apache
# Conocer la ip asignada al contenedor
$ docker inspect --format='{{.Name}} {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $ID_CONTAINER
```
## Usuarios Windows (Windows Issue).

Para correr el script en windows es necesario intalar las siguientes herramientas:
1. Cygwing (https://cygwin.com/install.html). Es un emulador de consola que permite la instalación de algunos paquetes linux. Al instalar Cygwin existe la opción de instalar paquetes.

#### Proceso de instalación Cygwin

    1.1. Al dar click en la instalación de cygwing, aparecerá la siguiente ventana, en la cual se debe aceptar la excepción de seguridad.
    ![Alt text](assets/DockerSiteBalancerCywingInstalation.PNG?raw=true "Projecto Docker Site Balancer")

    1.2. Dar clic en siguiente en la ventana de bienvenida.
![Alt text](assets/DockerSiteBalancerCywingInstalation2.PNG?raw=true "Projecto Docker Site Balancer")

    1.3. Seleccionar la instalación desde internet
![Alt text](assets/DockerSiteBalancerCywingInstalation3.PNG?raw=true "Projecto Docker Site Balancer")
    
    1.4. Seleccionar cualquier repositorio desde donde se instalarán los paquetes.
![Alt text](assets/DockerSiteBalancerCywingInstalation4.PNG?raw=true "Projecto Docker Site Balancer")
    
    1.5. Aparecerá una ventana que permite la búsqueda de los paquetes que se desea instalar en el entorno. Buscaremos e instalaremos los siguientes:
* vim
* nano 
* curl
* wget
* git
* jq

![Alt text](assets/DockerSiteBalancerCywingInstalation5.PNG?raw=true "Projecto Docker Site Balancer")

2. Docker Toolbox (https://docs.docker.com/toolbox/toolbox_install_windows/)
Permite la interacción con los contenedores docker desde windows. Desde esta consola tendremos la posibilidad de incresar y ejecutar el script start.

    2.1. Nos ubicamos en la carpeta del proyecto, como se muestra en el siguiente ejemplo.
    ![Alt text](assets/DockerSiteBalancerExec.PNG?raw=true "Projecto Docker Site Balancer")
    
    2.2. Al ejecutar el script nos mostrara un tecto de ayuda que indica cuales son los parametros que recibe. `-r: run, -i: install`
        ![Alt text](assets/DockerSiteBalancerExec2.PNG?raw=true "Ejecucion del script")