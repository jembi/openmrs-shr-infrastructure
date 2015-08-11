sudo service openxds stop
sudo -u postgres psql -c "drop database openxds; drop database log2;"
sudo -u postgres psql -c "create database openxds; create database log2;"
sudo -u postgres psql openxds < /opt/openxds/misc/create_database_schema_postgres.sql
sudo service openxds start
