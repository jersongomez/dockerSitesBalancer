# Contenedores Docker 
Ambientes en contenedores docker con posibilidad de balancear los site para el trafico de carga.
### Configuración
Antes de empezar con la instalación de nuestra imagen debemos configurar de manera correcta los siguentes archivos:
* **_configuration/balancer.conf_** : Archivo el cual contiene una estructura JSON con el fin de detectar si desea apps balanceados, este archivo debe contener todos los hosts para la configuración correcta del archivo `/etc/hosts` de nuestro container como de nuestro equipo local.
* **_configuration/httpd-vhosts-hw.conf_** : virtualhost de las app
* **_configuration/httpd-vhosts-secure.conf_** : virtualhost de las app
* **_configuration/httpd-vhosts-sites.conf_** : virtualhost de las app
* **_configuration/httpd-vhosts-webapps.conf_** : virtualhost de las app
* **_configuration/rutas.conf_** : este archivo contendra las rutas de sus apps del equipo local para compartirlas en su container el la ruta `/var/www/html/`

Ademas existe una carpeta `scripts/` la cual contiene los siguientes archivos:
###### Certificados SSL
* certificate.crt
* certificate.csr
* certificate.key

###### Archivo que nos ayudara con la creacion de los Virtualhost Balancer
* createBalancer.php

###### Llave publica y privada 
* securep.decameron.com.crt
* securep.decameron.com.key

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
$ ./startdocker.sh -i -a
```

Si ya cuenta con la instalación de la imagen y solo desea correr el contenedor ejecutar:
```sh
$ ./startdocker.sh -r -a
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
