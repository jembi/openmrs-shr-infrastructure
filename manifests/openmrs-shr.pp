$mysql_password = "shr"

# Defaults for Exec
Exec {
  path => ["/bin", "/sbin", "/usr/bin", "/usr/sbin", "/usr/local/bin", "/usr/local/sbin"],
  user => 'root',
}

# Packaging dependencies
package { "build-essential":
  ensure => latest
}

package { "devscripts":
  ensure => latest
}

# Install MySQL
package { "mysql-server":
  ensure => latest
}

# Install Java 8
exec { "install-java8":
  command => "echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections; sudo apt-get install oracle-java8-installer -y -q",
  timeout => 0
}

exec { "set-java8-default":
  command => "sudo apt-get install oracle-java8-set-default",
  timeout => 0,
  require => Exec["install-java8"]
}

# Install Tomcat 7
package { "tomcat7":
  ensure => latest,
  require => Exec["set-java8-default"]
}

# Fix Tomcat 7 to work with Java 8
exec { "fix-tomcat7":
  command => "sudo sed -i 's/\\(JDK_DIRS=.*\\)\"/\\1\\ \\/usr\\/lib\\/jvm\\/java\\-8\\-oracle\"/g' /etc/init.d/tomcat7",
  timeout => 0,
  require => Package["tomcat7"],
  notify => Service["tomcat7"]
}

# Fetch modules
exec { "fetch-xds-b-module":
  command => "wget -P /vagrant/artifacts/ https://s3.amazonaws.com/openshr/xds-b-repository-0.4.6-SNAPSHOT.omod",
  creates => "/vagrant/artifacts/xds-b-repository-0.4.6-SNAPSHOT.omod",
  timeout => 0
}

exec { "fetch-webservices-module":
  command => "wget -P /vagrant/artifacts/ https://modules.openmrs.org/modulus/api/releases/1138/download/webservices.rest-omod-2.9.omod",
  creates => "/vagrant/artifacts/webservices.rest-omod-2.9.omod",
  timeout => 0
}

exec { "fetch-contenthandler-module":
  command => "wget -P /vagrant/artifacts/ https://s3.amazonaws.com/openshr/shr-contenthandler-3.0.0-SNAPSHOT.omod",
  creates => "/vagrant/artifacts/shr-contenthandler-3.0.0-SNAPSHOT.omod",
  timeout => 0
}

exec { "fetch-odd-module":
  command => "wget -P /vagrant/artifacts/ https://s3.amazonaws.com/openshr/shr-odd-0.5.1.omod",
  creates => "/vagrant/artifacts/shr-odd-0.5.1.omod",
  timeout => 0
}

exec { "fetch-cdahandler-module":
  command => "wget -P /vagrant/artifacts/ https://s3.amazonaws.com/openshr/shr-cdahandler-0.6.0.omod",
  creates => "/vagrant/artifacts/shr-cdahandler-0.6.0.omod",
  timeout => 0
}

exec { "fetch-atna-module":
  command => "wget -P /vagrant/artifacts/ https://github.com/jembi/openmrs-module-shr-atna/releases/download/v0.5.0/shr-atna-0.5.0.omod",
  creates => "/vagrant/artifacts/shr-atna-0.5.0.omod",
  timeout => 0
}

exec { "copy-modules":
  command => "cp -f /vagrant/artifacts/*.omod /usr/share/tomcat7/.OpenMRS/modules/",
  user => "tomcat7",
  require => [ Exec["setup-openmrs-dir-permissions"], Exec["fetch-xds-b-module"], Exec["fetch-webservices-module"],
  Exec["fetch-contenthandler-module"], Exec["fetch-odd-module"], Exec["fetch-cdahandler-module"], Exec["fetch-atna-module"] ]
}

# Install OpenMRS
exec { "fetch-openmrs-war":
  command => "wget -O /vagrant/artifacts/openmrs.war https://s3.amazonaws.com/openshr/openmrs.war",
  creates => "/vagrant/artifacts/openmrs.war",
  timeout => 0
}

exec { "copy-webapp":
  command => "cp /vagrant/artifacts/openmrs.war /var/lib/tomcat7/webapps/",
  require => [ Package["tomcat7"], Exec["fetch-openmrs-war"], Exec["apply-db-dump"],
    Exec["openmrs-user-privileges"], Exec["copy-modules"] ]
}

exec { "setup-webapp-permissions":
  cwd => "/var/lib/tomcat7/webapps/",
  command => "chown -R tomcat7:tomcat7 openmrs.war",
  require => Exec["copy-webapp"]
}

# Initialise database
exec { "fetch-database":
  command => "wget -P /vagrant/artifacts/ https://s3.amazonaws.com/openshr/openmrs.sql.gz",
  creates => "/vagrant/artifacts/openmrs.sql.gz",
  timeout => 0
}

service { "mysql":
  enable => true,
  ensure => running,
  require => Package["mysql-server"],
}

exec { "mysqlpass":
  command => "mysqladmin -uroot password $mysql_password",
  require => Service["mysql"]
}

exec { "openmrs-user-password":
  alias => "mysqluserpass",
	command => "mysql -uroot -p${mysql_password} -e \"CREATE USER 'openmrs_user'@'localhost' IDENTIFIED BY 'jkH4rX0PORA3';\"",
  require => Exec["mysqlpass"]
}

exec { "gunzip-db-dump":
  command => "gunzip -c /vagrant/artifacts/openmrs.sql.gz > /tmp/openmrs.sql",
  require => Exec["fetch-database"]
}

exec { "create-openmrs-db":
  unless => "mysql -uroot -p${mysql_password} openmrs",
  command => "mysql -uroot -p${mysql_password} -e \"create database openmrs;\"",
  require => [ Service["mysql"], Exec["mysqlpass"] ],
}

exec { "openmrs-user-privileges":
	command => "mysql -uroot -p${mysql_password} -e \"GRANT ALL PRIVILEGES ON openmrs.* TO 'openmrs_user'@'localhost';\"",
	require => [ Exec["openmrs-user-password"], Exec["create-openmrs-db"] ]
}

exec { "apply-db-dump":
  command => "mysql -uroot -p${mysql_password} openmrs < /tmp/openmrs.sql",
  require => [ Service["mysql"], Exec["create-openmrs-db"], Exec["gunzip-db-dump"] ]
}

# Tomcat and OpenMRS app configuration
exec { "fetch-openmrs-conf":
  command => "wget -P /vagrant/artifacts/ https://s3.amazonaws.com/openshr/openmrs-conf-dir.tar.gz",
  creates => "/vagrant/artifacts/openmrs-conf-dir.tar.gz",
  timeout => 0
}

exec { "setup-openmrs-conf":
  cwd => "/usr/share/tomcat7",
  command => "tar -xzf /vagrant/artifacts/openmrs-conf-dir.tar.gz",
  require => [ Package["tomcat7"], Exec["fetch-openmrs-conf"] ]
}

exec { "setup-openmrs-dir-permissions":
  cwd => "/usr/share/tomcat7",
  command => "chown -R tomcat7:tomcat7 .",
  require => Exec["setup-openmrs-conf"]
}

# Define Tomcat service
service { "tomcat7":
    ensure  => "running",
    enable  => "true",
    require => Package["tomcat7"],
}

# Configure Tomcat memory
file { "/usr/share/tomcat7/bin/setenv.sh":
  source  => "/vagrant/artifacts/setenv.sh",
  owner => "tomcat7",
  group   => "tomcat7",
  mode  => "a+x",
  require => Package["tomcat7"],
  notify  => Service["tomcat7"]
}

# Setup document directory
exec { "setup-document-directory":
  command => "sudo mkdir -p /var/lib/tomcat7/null/xdslog/sentMessages",
  require => Package["tomcat7"]
}

exec { "setup-document-permissions":
  command => "sudo chown -R tomcat7:tomcat7 /var/lib/tomcat7/null",
  require => Exec["setup-document-directory"]
}
