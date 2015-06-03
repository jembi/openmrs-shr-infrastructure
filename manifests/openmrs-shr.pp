$mysql_password = "shr"

# defaults for Exec
Exec {
  path => ["/bin", "/sbin", "/usr/bin", "/usr/sbin", "/usr/local/bin", "/usr/local/sbin"],
  user => 'root',
}

# Make sure package index is updated (when referenced by require)
exec { "apt-get update":
  command => "apt-get update",
  user => "root",
}

# Install these packages after apt-get update
define apt::package($ensure='latest') {
  package { $name:
  ensure => $ensure,
  require => Exec['apt-get update'];
  }
}

apt::package { "mysql-server": ensure => latest }
apt::package { "openjdk-7-jdk": ensure => latest }
# apt::package { "maven": ensure => latest }
apt::package { "tomcat6": ensure => latest }
# apt::package { "git": ensure => latest }
apt::package { "vim": ensure => latest }


# Fetch modules

# define shr::module($depends="") {
#   vcsrepo { "/home/vagrant/${name}":
#     ensure => present,
#     provider => git,
#     source => "git://github.com/jembi/${name}.git",
#     revision => "master",
#     require => Package["git"]
#   }

#   exec { "setup-${name}-dir-permissions":
#     cwd => "/home/vagrant",
#     command => "chown -R vagrant:vagrant ${name}",
#     require => Vcsrepo["/home/vagrant/${name}"]
#   }

#   if $depends == "" {
#     exec { "${name}":
#       cwd => "/home/vagrant/${name}",
#       command => "mvn install -DskipTests=true",
#       timeout => 0,
#       user => "vagrant",
#       require => [ Package["openjdk-6-jdk"], Package["maven"],
#         Exec["setup-${name}-dir-permissions"] ]
#     }
#   } else {
#     exec { "${name}":
#       cwd => "/home/vagrant/${name}",
#       command => "mvn install -DskipTests=true",
#       timeout => 0,
#       user => "vagrant",
#       require => [ Package["openjdk-6-jdk"], Package["maven"],
#         Exec["setup-${name}-dir-permissions"], Exec["${depends}"] ]
#     }
#   }
# }

# shr::module { "openmrs-module-shr-cdahandler": }
# shr::module { "openmrs-module-shr-unstructureddata": }
# shr::module { "openmrs-module-shr-contenthandler": }
# shr::module { "openmrs-module-shr-rest": depends => "openmrs-module-shr-contenthandler" }

# $cdaOmod = "/home/vagrant/openmrs-module-shr-cdahandler/omod/target/*.omod"
# $udOmod = "/home/vagrant/openmrs-module-shr-unstructureddata/omod/target/*.omod"
# $chOmod = "/home/vagrant/openmrs-module-shr-contenthandler/omod/target/*.omod"
# $restOmod = "/home/vagrant/openmrs-module-shr-rest/omod/target/*.omod"



exec { "fetch-xds-b-module":
  command => "wget -P /vagrant/artifacts/ https://github.com/jembi/openmrs-module-shr-xds-b-repository/releases/download/v0.4.5/xds-b-repository-0.4.5.omod",
  creates => "/vagrant/artifacts/xds-b-repository-0.4.5.omod",
  timeout => 0
}

exec { "fetch-webservices-module":
  command => "wget -P /vagrant/artifacts/ https://modules.openmrs.org/modulus/api/releases/1138/download/webservices.rest-omod-2.9.omod",
  creates => "/vagrant/artifacts/webservices.rest-omod-2.9.omod",
  timeout => 0
}

exec { "fetch-contenthandler-module":
  command => "wget -P /vagrant/artifacts/ https://github.com/jembi/openmrs-module-shr-contenthandler/releases/download/v2.2.0/shr-contenthandler-2.2.0.omod",
  creates => "/vagrant/artifacts/shr-contenthandler-2.2.0.omod",
  timeout => 0
}

exec { "fetch-odd-module":
  command => "wget -P /vagrant/artifacts/ https://github.com/jembi/openmrs-module-shr-odd/releases/download/v0.5.1/shr-odd-0.5.1.omod",
  creates => "/vagrant/artifacts/shr-odd-0.5.1.omod",
  timeout => 0
}

exec { "fetch-cdahandler-module":
  command => "wget -P /vagrant/artifacts/ https://github.com/jembi/openmrs-module-shr-cdahandler/releases/download/v0.6.0/shr-cdahandler-0.6.0.omod",
  creates => "/vagrant/artifacts/shr-cdahandler-0.6.0.omod",
  timeout => 0
}

exec { "fetch-atna-module":
  command => "wget -P /vagrant/artifacts/ https://github.com/jembi/openmrs-module-shr-atna/releases/download/v0.5.0/shr-atna-0.5.0.omod",
  creates => "/vagrant/artifacts/shr-atna-0.5.0.omod",
  timeout => 0
}

exec { "copy-modules":
  command => "cp -f /vagrant/artifacts/*.omod /usr/share/tomcat6/.OpenMRS/modules/",
  user => "tomcat6",
  require => [ Exec["setup-openmrs-dir-permissions"], Exec["fetch-xds-b-module"], Exec["fetch-webservices-module"],
  Exec["fetch-contenthandler-module"], Exec["fetch-odd-module"], Exec["fetch-cdahandler-module"], Exec["fetch-atna-module"] ]
}

# Install OpenMRS

exec { "fetch-openmrs-war":
  command => "wget -O /vagrant/artifacts/openmrs.war http://sourceforge.net/projects/openmrs/files/releases/OpenMRS_1.9.7/openmrs.war/download",
  creates => "/vagrant/artifacts/openmrs.war",
  timeout => 0
}

exec { "copy-webapp":
  command => "cp /vagrant/artifacts/openmrs.war /var/lib/tomcat6/webapps/",
  require => [ Package["tomcat6"], Exec["fetch-openmrs-war"], Exec["apply-db-dump"],
    Exec["openmrs-user-privileges"], Exec["copy-modules"] ]
}

# Initialise Database

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

# exec { "copy-catalina-sh":
#   command => "cp /vagrant/artifacts/catalina.sh /usr/share/tomcat6/bin/",
#   require => Package["tomcat6"]
# }

exec { "setup-openmrs-conf":
  cwd => "/usr/share/tomcat6",
  command => "tar -xzf /vagrant/artifacts/openmrs-conf-dir.tar.gz",
  require => Package["tomcat6"]
}

exec { "setup-openmrs-dir-permissions":
  cwd => "/usr/share/tomcat6",
  command => "chown -R tomcat6:tomcat6 .OpenMRS",
  require => Exec["setup-openmrs-conf"]
}

# Configure Tomcat memory

# Define Tomcat service
service { "tomcat6":
    ensure  => "running",
    enable  => "true",
    require => Package["tomcat6"],
}

file { "/usr/share/tomcat6/bin/setenv.sh":
  source  => "/vagrant/artifacts/setenv.sh",
  owner => "tomcat6",
  group   => "tomcat6",
  mode  => "a+x",
  require => Package["tomcat6"],
  notify  => Service["tomcat6"]
}
