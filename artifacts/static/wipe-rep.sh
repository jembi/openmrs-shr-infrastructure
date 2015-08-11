mysql -u root -pshr -e "drop database openmrs;"
mysql -u root -pshr -e "create database openmrs;"
gunzip -c /vagrant/artifacts/openmrs.sql.gz > /tmp/openmrs.sql
mysql -u root -pshr openmrs < /tmp/openmrs.sql
echo Done
