
Build:
```
sudo docker build -t my-apache2 .
```
Run:
```
sudo docker stop apache-proxy; \
sudo docker rm apache-proxy; \
sudo docker build -t my-apache2 . ; \
sudo docker run -dit   --name=apache-proxy  --net=cbio-net  -v "$PWD":/usr/local/apache2/htdocs/   -p 443:443 -p 10443:10443    my-apache2; \
sudo docker ps; \
sudo docker logs apache-proxy;
```

Generate self-signed certificate (for testing purposes):
```
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout key.key -out cert.crt -subj '/CN=localhost'
```


Add to custom .conf file:
```
<VirtualHost *:80>
  ServerName localhost

  ProxyRequests Off
  <Proxy *>
    Require all granted
  </Proxy>

  ErrorLog /var/log/apache2/cbio_http_error.log
  LogLevel warn
  CustomLog /var/log/apache2/cbio_http_access.log combined

  ProxyPass        / http://cbioportal-container:8082/
  ProxyPassReverse / http://cbioportal-container:8082/
  ProxyPreserveHost On
</VirtualHost>
```

TODO: change to redirect:
```
<VirtualHost *:80>
                ServerName <servername.url>
                Redirect / https://<servername.url>/
                RewriteEngine On
                RewriteCond %{REQUEST_METHOD} ^(TRACE|TRACK)
                RewriteRule .* - [F]

</VirtualHost>
```        


For tomcat: 
```
<VirtualHost *:443>

  SSLEngine on
  #SSLCertificateChainFile /etc/ssl/cbio_https/cert.pem
  #SSLCertificateFile /etc/ssl/cbio_https/cert.pem
  #SSLCertificateKeyFile /etc/ssl/cbio_https/key.nopass.pem
  SSLCertificateFile /etc/ssl/cbio_https/cert.crt
  SSLCertificateKeyFile /etc/ssl/cbio_https/key.key
  
  # ServerName <yourserver.com>
  ServerName localhost
  
  ProxyRequests Off
  <Proxy *>
    Require all granted
  </Proxy>

  Header edit Location ^http: https:
  Header edit Set-Cookie "(?i); ?secure\b" ""
  Header edit Set-Cookie $ "; secure"

  Header always set Strict-Transport-Security "max-age=15768000"

  ErrorLog /tmp/cbio_https_error.log
  LogLevel warn
  CustomLog /tmp/https_access.log combined

  ProxyPass / http://cbioportal-container:8080/
  ProxyPassReverse / http://cbioportal-container:8080/
  ProxyPreserveHost On
</VirtualHost>
```
For keycloak:
```
<VirtualHost *:10443>

  SSLEngine on
  SSLCertificateFile /etc/ssl/cbio_https/cert.crt
  SSLCertificateKeyFile /etc/ssl/cbio_https/key.key

  # ServerName yourserver.com
  ServerName localhost
  
  ProxyRequests Off
  <Proxy *>
    Require all granted
  </Proxy>

  Header edit Location ^http: https:
  Header edit Set-Cookie "(?i); ?secure\b" ""
  Header edit Set-Cookie $ "; secure"

  Header always set Strict-Transport-Security "max-age=15768000"

  ErrorLog /tmp/cbio_https_error.log
  LogLevel warn
  #CustomLog /tmp/https_access.log combined

  ProxyPass / http://keycloak-container:8080/
  ProxyPassReverse / http://keycloak-container:8080/
  ProxyPreserveHost On

</VirtualHost>
```
