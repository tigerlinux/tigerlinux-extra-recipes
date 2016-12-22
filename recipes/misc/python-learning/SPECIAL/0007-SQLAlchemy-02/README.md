# Python Exercises, from basic to not-so-basic - SQLAlchemy Sample with MySQL/MariaDB

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## Python and SQLAlchemy - MySQL/MariaDB.

The exercise in this directory (`sqlalchemy-mysql-mariadb.py`) show one of the many ways you can use python to perform simple database operations. We are basing this exercise on SQLAlchemy 1.0.x. Take into account changes between SQLAlchemy versions if you use another version.


## Dependencies needed for this exercise.

Apart from python (of course), you'll need sqlalchemy and pymysql. You can install them from your O/S distro, or, by using `pip install`:

**Generic Python Version**

```bash
pip install sqlachemy
pip install pymysql
```

**OS with both version 2 and 3... like Fedora 22,23 or 24**

```bash
pip2 install sqlalchemy
pip2 install pymysql
pip3 install sqlalchemy
pip3 install pymysql
```

Also, need access to a MySQL/MariaDB database. If you don't have one, you can use "docker" (install it first, and also install mysql/mariadb client libraries and command tools) in order to create both the database-engine container, and later create the database:

**Docker MariaDB Container creation command:**

```bash
docker run --name mymariadb -e MYSQL_ROOT_PASSWORD="P@ssw0rd" -p 127.0.0.1:3306:3306 -d mariadb
```

**Database creation commands:**

```bash
mysql -h 127.0.0.1 -u root -p"P@ssw0rd"

MariaDB [(none)]> CREATE DATABASE mydb CHARACTER SET utf8 COLLATE utf8_general_ci;
MariaDB [(none)]> GRANT ALL PRIVILEGES ON mydb.* TO 'mydbuser'@'%' IDENTIFIED BY 'P@ssw0rd' WITH GRANT OPTION;
MariaDB [(none)]> FLUSH PRIVILEGES;
MariaDB [(none)]> exit
```

Test your database access to the container with:

```bash
mysql -h 127.0.0.1 -u mydbuser -p"P@ssw0rd" mydb
```

At the beggining of the script (`sqlalchemy-mysql-mariadb.py`) you can change the database access info if you want to use another mysql/mariadb engine/database instead of a dockerized solution:

```bash
dbhost="127.0.0.1"
dbport="3306"
dbname="mydb"
dbuser="mydbuser"
dbpass="P@ssw0rd"
```

If you can't access your database, you'll see something like:

```bash
sqlalchemy.exc.OperationalError: (pymysql.err.OperationalError) (2003, "Can't connect to MySQL server on '127.0.0.1' ([Errno 111] Connection refused)")
```


