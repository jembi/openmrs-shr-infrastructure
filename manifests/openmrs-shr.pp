$mysql_password = "shr"

# defaults for Exec
Exec {
    path => ["/bin", "/sbin", "/usr/bin", "/usr/sbin", "/usr/local/bin", "/usr/local/sbin"],
    user => 'root',
}

# Add an apt cacher server
exec { "Configure apt-cacher proxy":
    command => "echo \"Acquire::http::Proxy \\\"http://192.168.1.53:3142\\\";\" > /etc/apt/apt.conf.d/01JembiServerproxy",
    user => "root",
}

# Make sure package index is updated (when referenced by require)
exec { "apt-get update":
    command => "apt-get update",
    user => "root",
    require => Exec["Configure apt-cacher proxy"]
}

# Install these packages after apt-get update
define apt::package($ensure='latest') {
    package { $name:
        ensure => $ensure,
        require => Exec['apt-get update'];
    }
}

apt::package { "mysql-server": ensure => latest }
apt::package { "openjdk-6-jdk": ensure => latest }
apt::package { "maven": ensure => latest }
apt::package { "tomcat6": ensure => latest }
apt::package { "git": ensure => latest }
apt::package { "vim": ensure => latest }


# Modules

define shr::module($depends="") {
    vcsrepo { "/home/vagrant/${name}":
        ensure => present,
        provider => git,
        source => "git://github.com/jembi/${name}.git",
        revision => "master",
        require => Package["git"]
    }

    exec { "setup-${name}-dir-permissions":
        cwd => "/home/vagrant",
        command => "chown -R vagrant:vagrant ${name}",
        require => Vcsrepo["/home/vagrant/${name}"]
    }

    if $depends == "" {
        exec { "${name}":
            cwd => "/home/vagrant/${name}",
            command => "mvn install -DskipTests=true",
            timeout => 0,
            user => "vagrant",
            require => [ Package["openjdk-6-jdk"], Package["maven"],
                Exec["setup-${name}-dir-permissions"] ]
        }
    } else {
        exec { "${name}":
            cwd => "/home/vagrant/${name}",
            command => "mvn install -DskipTests=true",
            timeout => 0,
            user => "vagrant",
            require => [ Package["openjdk-6-jdk"], Package["maven"],
                Exec["setup-${name}-dir-permissions"], Exec["${depends}"] ]
        }
    }
}

shr::module { "openmrs-module-shr-cdahandler": }
shr::module { "openmrs-module-shr-unstructureddata": }
shr::module { "openmrs-module-shr-contenthandler": }
shr::module { "openmrs-module-shr-rest": depends => "openmrs-module-shr-contenthandler" }

$cdaOmod = "/home/vagrant/openmrs-module-shr-cdahandler/omod/target/*.omod"
$udOmod = "/home/vagrant/openmrs-module-shr-unstructureddata/omod/target/*.omod"
$chOmod = "/home/vagrant/openmrs-module-shr-contenthandler/omod/target/*.omod"
$restOmod = "/home/vagrant/openmrs-module-shr-rest/omod/target/*.omod"

exec { "copy-modules":
    command => "cp /vagrant/artifacts/*.omod ${cdaOmod} ${udOmod} ${chOmod} ${restOmod} /usr/share/tomcat6/.OpenMRS/modules/",
    require => [ Exec["setup-openmrs-dir-permissions"],
        Exec["openmrs-module-shr-cdahandler"], Exec["openmrs-module-shr-unstructureddata"],
        Exec["openmrs-module-shr-contenthandler"], Exec["openmrs-module-shr-rest"] ]
}

# OpenMRS

exec { "fetch-openmrs-war":
    command => "wget -O /vagrant/artifacts/openmrs.war http://sourceforge.net/projects/openmrs/files/releases/OpenMRS_1.9.7/openmrs.war/download",
    creates => "/vagrant/artifacts/openmrs.war",
    timeout => 0,
}

exec { "copy-webapp":
    command => "cp /vagrant/artifacts/openmrs.war /var/lib/tomcat6/webapps/",
    require => [ Package["tomcat6"], Exec["fetch-openmrs-war"] ]
}

# Database

service { "mysql":
    enable => true,
    ensure => running,
    require => Package["mysql-server"],
}

exec { "mysqlpass":
    command => "mysqladmin -uroot password $mysql_password",
    require => Service["mysql"]
}

exec { "gunzip-db-dump":
    command => "gunzip -c /vagrant/artifacts/openmrs.sql.gz > /tmp/openmrs.sql",
}

exec { "create-openmrs-db":
    unless => "mysql -uroot -p${mysql_password} openmrs",
    command => "mysql -uroot -p${mysql_password} -e \"create database openmrs;\"",
    require => [ Service["mysql"], Exec["mysqlpass"] ],
}

exec { "apply-db-dump":
    command => "mysql -uroot -p${mysql_password} openmrs < /tmp/openmrs.sql",
    require => [ Service["mysql"], Exec["create-openmrs-db"], Exec["gunzip-db-dump"] ]
}

# Tomcat and OpenMRS app configuration

exec { "copy-catalina-sh":
    command => "cp /vagrant/artifacts/catalina.sh /usr/share/tomcat6/bin/",
    require => Package["tomcat6"]
}

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

service { "tomcat6":
    restart => true,
    require => [ Exec["copy-modules"], Exec["copy-webapp"], Exec["copy-catalina-sh"],
        Exec["setup-openmrs-dir-permissions"], Exec["apply-db-dump"] ]
}
