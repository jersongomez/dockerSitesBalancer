#!/usr/bin/php
<?php
new Balancer($argv);

class Balancer
{

    function __construct($argv)
    {
        echo "\nCreando configuracion del balanceador ...\n";
        $this->createBalanceFile();
    }

    function buildFile($principal, $nodos, $port, $numBalancer){
	$i = 1;
	$urlsReverse = "";
        $urlsBalance = "";
	$complementoSSl = "";
	foreach ($nodos as $site) {
            $urlsReverse .= "ProxyPassReverse / http://{$site}/\n";
            $urlsBalance .= "BalancerMember http://{$site} route=node{$i}\n";
            $i++;
        }

	if($port != 80){
	$complementoSSl = "SSLEngine on
			    SSLCertificateFile /etc/pki/tls/certs/certificate.crt
			    SSLCertificateKeyFile /etc/pki/tls/private/certificate.key";
	}

        $vHost = "echo '<VirtualHost *:$port>

			    ServerName $principal
			    $complementoSSl
			    # Actuamos como reverse proxy, apareciendo a los clientes
			    # como un servidor web corriente.
			    ProxyRequests Off

			    # Acceso sin restringir.
			    <Proxy *>
			      Order deny,allow
			      Allow from all
			    </Proxy>

			    # El recurso balancer-manager será el único servido localmente.
			    # El resto, lo pasaremos a balancer://mycluster/, que veremos
			    # se trata del recurso de balanceo formado por los backends.
			    ProxyPass /balancer-manager !
			    ProxyPass / balancer://mycluster/ nofailover=On
			    # Reescbirimos la URL en las cabeceras HTTP Location,
			    # Content-Location y URI para que en lugar de los requests
			    # locales (frontend), figuren como remotos (backends).
			    $urlsReverse
			    # Añadimos miembros (backends) al grupo de balanceo y definimos
			    # el método del mismo. En este caso, balancemos por número de
			    # requests.
				Header add Set-Cookie \"ROUTEID=.%{BALANCER_WORKER_ROUTE}e; path=/\" env=BALANCER_ROUTE_CHANGED
			    <Proxy balancer://mycluster>
				$urlsBalance
				ProxySet stickysession=ROUTEID
			      #ProxySet lbmethod=bytraffic
			    </Proxy>

			    # Habilitamos el sencillo interfaz web de management del
			    # balanceador. Convendría restringir acceso y protegerlo con
			    # contraseña.
			    # contraseña.
			    <Location /balancer-manager>
			      SetHandler balancer-manager
			      Order deny,allow
			      Allow from all
			    </Location>

			</VirtualHost>'";

        $vHostPath = '/etc/httpd/conf/httpd-vhost-balancer'.$numBalancer.'.conf';
        `$vHost > $vHostPath `;
	
        if (is_file($vHostPath) && !empty($vHostPath)) {
            echo " \- vhost balancer ($principal) creado correctamente [finish]\n";
        } else {
            echo " \- Error, creando vhost ($principal) [finish]\n";
        }


    }

    function createBalanceFile()
    {                
        $file = '/scripts/balancer.conf';
        $fileOpen = fopen($file, "r");
        $configuration = json_decode(fread($fileOpen, 2000));
        fclose($fileOpen);
	$numBalancer = 1;

	foreach($configuration as $key => $value){
		if(isset($value->sites) && $value->sites != ""){
			$this->buildFile($value->principal,$value->sites,$value->port,$numBalancer);
			$numBalancer++;
		}
	}
        
    }

}

