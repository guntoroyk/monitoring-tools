#! /bin/sh

# Download and Install the Latest Updates for the OS
apt-get update && apt-get upgrade -y

# Set the Server Timezone to CST
echo "Asia/Jakarta" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

# Install essential packages
apt-get -y install htop

# Install MySQL Server in a Non-Interactive mode. Default root password will be "root"
echo "mysql-server-8.0 mysql-server/root_password password root" | sudo debconf-set-selections
echo "mysql-server-8.0 mysql-server/root_password_again password root" | sudo debconf-set-selections
apt-get -y install mysql-server-8.0


# Run the MySQL Secure Installation wizard
mysql_secure_installation

sed -i 's/127\.0\.0\.1/0\.0\.0\.0/g' /etc/mysql/my.cnf
mysql -uroot -p -e 'USE mysql; UPDATE `user` SET `Host`="%" WHERE `User`="root" AND `Host`="localhost"; DELETE FROM `user` WHERE `Host` != "%" AND `User`="root"; FLUSH PRIVILEGES;'

service mysql restart