#!/bin/bash

set -euo pipefail

# Update and install critical packages
LOG_FILE="/tmp/ec2_bootstrap.sh.log"
echo "Logging to \"$LOG_FILE\" ..."

echo "Installing essential packages via apt-get in non-interactive mode ..." | tee -a $LOG_FILE
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" upgrade
apt-get install -y zip unzip curl bzip2 python-dev build-essential git libssl1.0.0 libssl-dev \
    software-properties-common debconf-utils

# Update the motd message to create instructions for users when they ssh in
echo "Updating motd boot message with instructions for the user of the image ..." | tee -a $LOG_FILE
apt-get install -y update-motd
sudo -u ubuntu tee /home/ubuntu/agile_data_science.message << END_HELLO

------------------------------------------------------------------------------------------------------------------------
Welcome to Agile Data Science 2.0!

If the Agile_Data_Code_2 directory (and others for hadoop, spark, mongodb, elasticsearch, etc.) aren't present, please wait a few minutes for the install script to finish.

Book reader, now you need to run the download scripts! To do so, run the following commands:

cd Agile_Data_Code_2
./download.sh

Video viewers and free spirits, to skip ahead to chapter 8, you will need to run the following command:

cd Agile_Data_Code_2
ch08/download_data.sh

Those working chapter 10, on the weather, will need to run the following commands:

cd Agile_Data_Code_2
./download_weather.sh

Note: to run the web applications and view them at http://localhost:5000 you will now need to run the ec2_create_tunnel.sh script from your local machine.

If you have problems, please file an issue at https://github.com/rjurney/Agile_Data_Code_2/issues
------------------------------------------------------------------------------------------------------------------------

For help building 'big data' applications like this one, or for training regarding same, contact Russell Jurney <rjurney@datasyndrome.com> or find more information at http://datasyndrome.com

Enjoy! Russell Jurney @rjurney <russell.jurney@gmail.com> http://linkedin.com/in/russelljurney

END_HELLO

tee /etc/update-motd.d/99-agile-data-science <<EOF
#!/bin/bash

cat /home/ubuntu/agile_data_science.message
EOF
chmod 0755 /etc/update-motd.d/99-agile-data-science
update-motd

#
# Install Java and setup ENV
#
echo "Installing and configuring Java 8 from Oracle ..." | tee -a $LOG_FILE
add-apt-repository -y ppa:webupd8team/java
apt-get update
echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections
apt-get install -y oracle-java8-installer oracle-java8-set-default

export JAVA_HOME=/usr/lib/jvm/java-8-oracle
echo "export JAVA_HOME=/usr/lib/jvm/java-8-oracle" | sudo -u ubuntu tee -a /home/ubuntu/.bash_profile

#
# Install Miniconda
#
echo "Installing and configuring miniconda3 latest ..." | tee -a $LOG_FILE
curl -Lko /tmp/Miniconda3-latest-Linux-x86_64.sh https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
chmod +x /tmp/Miniconda3-latest-Linux-x86_64.sh
/tmp/Miniconda3-latest-Linux-x86_64.sh -b -p /home/ubuntu/anaconda

export PATH=/home/ubuntu/anaconda/bin:$PATH
echo 'export PATH=/home/ubuntu/anaconda/bin:$PATH' | sudo -u ubuntu tee -a /home/ubuntu/.bash_profile

chown -R ubuntu /home/ubuntu/anaconda
chgrp -R ubuntu /home/ubuntu/anaconda

#
# Install Clone repo, install Python dependencies
#
echo "Cloning https://github.com/rjurney/Agile_Data_Code_2 repository and installing dependencies ..." \
  | tee -a $LOG_FILE
cd /home/ubuntu
sudo -u ubuntu git clone https://github.com/rjurney/Agile_Data_Code_2
cd /home/ubuntu/Agile_Data_Code_2
export PROJECT_HOME=/home/ubuntu/Agile_Data_Code_2
echo "export PROJECT_HOME=/home/ubuntu/Agile_Data_Code_2" | sudo -u ubuntu tee -a /home/ubuntu/.bash_profile
su ubuntu --login -c 'conda install -y python=3.6'
#conda install -y python=3.5
#Solving environment: failed
#
#UnsatisfiableError: The following specifications were found to be in conflict:
#  - conda[version='>=4.5.12'] -> enum34 -> python[version='>=2.7,<2.8.0a0']
#  - python=3.5
#Use "conda info <package>" to see the dependencies for each package.
su ubuntu --login -c 'conda install -y iso8601 numpy scipy scikit-learn matplotlib ipython jupyter'

sudo -u ubuntu tee requirements.txt <<EOF
Flask
apache-airflow
beautifulsoup4
bs4
frozendict
geopy
ipython
kafka-python
matplotlib
numpy
py4j
pyelasticsearch
pymongo
requests
scipy
selenium
sklearn
tabulate
tldextract
wikipedia
findspark
iso8601
notebook
EOF

su ubuntu --login \
    -c 'SLUGIFY_USES_TEXT_UNIDECODE=yes pip install -r /home/ubuntu/Agile_Data_Code_2/requirements.txt'

#ubuntu@ip-10-0-0-206:~/Agile_Data_Code_2$ pip install -r requirements.txt
#Collecting Flask (from -r requirements.txt (line 1))
#  Downloading https://files.pythonhosted.org/packages/7f/e7/08578774ed4536d3242b14dacb4696386634607af824ea997202cd0edb4b/Flask-1.0.2-py2.py3-none-any.whl (91kB)
#    100% |████████████████████████████████| 92kB 3.9MB/s
#Collecting airflow (from -r requirements.txt (line 2))
#  Downloading https://files.pythonhosted.org/packages/98/e7/d8cad667296e49a74d64e0a55713fcd491301a2e2e0e82b94b065fda3087/airflow-0.6.tar.gz
#    Complete output from command python setup.py egg_info:
#    running egg_info
#    creating pip-egg-info/airflow.egg-info
#    writing pip-egg-info/airflow.egg-info/PKG-INFO
#    writing dependency_links to pip-egg-info/airflow.egg-info/dependency_links.txt
#    writing top-level names to pip-egg-info/airflow.egg-info/top_level.txt
#    writing manifest file 'pip-egg-info/airflow.egg-info/SOURCES.txt'
#    reading manifest file 'pip-egg-info/airflow.egg-info/SOURCES.txt'
#    writing manifest file 'pip-egg-info/airflow.egg-info/SOURCES.txt'
#    Traceback (most recent call last):
#      File "<string>", line 1, in <module>
#      File "/tmp/pip-install-zheb9_d4/airflow/setup.py", line 32, in <module>
#        raise RuntimeError('Please install package apache-airflow instead of airflow')
#    RuntimeError: Please install package apache-airflow instead of airflow
#
#    ----------------------------------------
#Command "python setup.py egg_info" failed with error code 1 in /tmp/pip-install-zheb9_d4/airflow/

cd /home/ubuntu

# Install commons-httpclient
sudo -u ubuntu curl -Lko /home/ubuntu/Agile_Data_Code_2/lib/commons-httpclient-3.1.jar http://central.maven.org/maven2/commons-httpclient/commons-httpclient/3.1/commons-httpclient-3.1.jar

#
# Install Hadoop
#
echo "" | tee -a $LOG_FILE
echo "Downloading and installing Hadoop 3.0.1 ..." | tee -a $LOG_FILE
sudo -u ubuntu curl -Lko /tmp/hadoop-3.0.1.tar.gz https://archive.apache.org/dist/hadoop/common/hadoop-3.0.1/hadoop-3.0.1.tar.gz
sudo -u ubuntu mkdir -p /home/ubuntu/hadoop
cd /home/ubuntu/
sudo -u ubuntu tar -xvf /tmp/hadoop-3.0.1.tar.gz -C hadoop --strip-components=1

echo "Configuring Hadoop 3.0.1 ..." | tee -a $LOG_FILE
echo "" >> /home/ubuntu/.bash_profile
echo '# Hadoop environment setup' | sudo -u ubuntu tee -a /home/ubuntu/.bash_profile
export HADOOP_HOME=/home/ubuntu/hadoop
echo 'export HADOOP_HOME=/home/ubuntu/hadoop' | sudo -u ubuntu tee -a /home/ubuntu/.bash_profile
export PATH=$PATH:$HADOOP_HOME/bin
echo 'export PATH=$PATH:$HADOOP_HOME/bin' | sudo -u ubuntu tee -a /home/ubuntu/.bash_profile
export HADOOP_CLASSPATH=$(hadoop classpath)
echo 'export HADOOP_CLASSPATH=$(hadoop classpath)' | sudo -u ubuntu tee -a /home/ubuntu/.bash_profile
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
echo 'export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop' | sudo -u ubuntu tee -a /home/ubuntu/.bash_profile

#
# Install Spark
#
echo "" | tee -a $LOG_FILE
echo "Downloading and installing Spark 2.2.1 ..." | tee -a $LOG_FILE
#curl -Lko /tmp/spark-2.2.1-bin-without-hadoop.tgz http://apache.mirrors.lucidnetworks.net/spark/spark-2.2.1/spark-2.2.1-bin-hadoop2.7.tgz
sudo -u ubuntu curl -Lko /tmp/spark-2.2.1-bin-without-hadoop.tgz https://archive.apache.org/dist/spark/spark-2.2.1/spark-2.2.1-bin-hadoop2.7.tgz
sudo -u ubuntu mkdir -p /home/ubuntu/spark
cd /home/ubuntu
sudo -u ubuntu tar -xvf /tmp/spark-2.2.1-bin-without-hadoop.tgz -C spark --strip-components=1

echo "Configuring Spark 2.2.1 ..." | tee -a $LOG_FILE
echo "" >> /home/ubuntu/.bash_profile
echo "# Spark environment setup" | sudo tee -a /home/ubuntu/.bash_profile
export SPARK_HOME=/home/ubuntu/spark
echo 'export SPARK_HOME=/home/ubuntu/spark' | sudo tee -a /home/ubuntu/.bash_profile
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop/
echo 'export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop/' | sudo tee -a /home/ubuntu/.bash_profile
export SPARK_DIST_CLASSPATH=`$HADOOP_HOME/bin/hadoop classpath`
echo 'export SPARK_DIST_CLASSPATH=`$HADOOP_HOME/bin/hadoop classpath`' | sudo tee -a /home/ubuntu/.bash_profile
export PATH=$PATH:$SPARK_HOME/bin
echo 'export PATH=$PATH:$SPARK_HOME/bin' | sudo tee -a /home/ubuntu/.bash_profile

# Have to set spark.io.compression.codec in Spark local mode
sudo -u ubuntu cp /home/ubuntu/spark/conf/spark-defaults.conf.template /home/ubuntu/spark/conf/spark-defaults.conf
echo 'spark.io.compression.codec org.apache.spark.io.SnappyCompressionCodec' | sudo tee -a /home/ubuntu/spark/conf/spark-defaults.conf

# Give Spark 25GB of RAM, use Python3
echo "spark.driver.memory 50g" | sudo tee -a $SPARK_HOME/conf/spark-defaults.conf
echo "spark.executor.cores 12" | sudo tee -a $SPARK_HOME/conf/spark-defaults.conf
echo "PYSPARK_PYTHON=python3" | sudo -u ubuntu tee -a $SPARK_HOME/conf/spark-env.sh
echo "PYSPARK_DRIVER_PYTHON=python3" | sudo tee -a $SPARK_HOME/conf/spark-env.sh

# Setup log4j config to reduce logging output
sudo -u ubuntu cp $SPARK_HOME/conf/log4j.properties.template $SPARK_HOME/conf/log4j.properties
sudo -u ubuntu sed -i 's/INFO/ERROR/g' $SPARK_HOME/conf/log4j.properties

#
# Install MongoDB and dependencies
#
echo "" | tee -a $LOG_FILE
echo "Installing MongoDB via apt-get ..." | tee -a $LOG_FILE
apt-get install -y mongodb
sudo mkdir -p /data/db
chown -R mongodb /data/db
chgrp -R mongodb /data/db

# run MongoDB as daemon
echo "Running MongoDB as a daemon ..." | tee -a $LOG_FILE
systemctl start mongodb

# Get the MongoDB Java Driver
echo "Fetching the MongoDB Java driver ..." | tee -a $LOG_FILE
sudo -u ubuntu curl -Lko /home/ubuntu/Agile_Data_Code_2/lib/mongo-java-driver-3.4.2.jar http://central.maven.org/maven2/org/mongodb/mongo-java-driver/3.4.2/mongo-java-driver-3.4.2.jar

# Install the mongo-hadoop project in the mongo-hadoop directory in the root of our project.
echo "" | tee -a $LOG_FILE
echo "Downloading and installing the mongo-hadoop project version 2.0.2 ..." | tee -a $LOG_FILE
sudo -u ubuntu curl -Lko /tmp/mongo-hadoop-r2.0.2.tar.gz https://github.com/mongodb/mongo-hadoop/archive/r2.0.2.tar.gz
sudo -u ubuntu mkdir /home/ubuntu/mongo-hadoop
cd /home/ubuntu
sudo -u ubuntu tar -xvzf /tmp/mongo-hadoop-r2.0.2.tar.gz -C mongo-hadoop --strip-components=1
sudo -u ubuntu rm -rf /tmp/mongo-hadoop-r2.0.2.tar.gz

# Now build the mongo-hadoop-spark jars
echo "Building mongo-hadoop-spark jars ..." | tee -a $LOG_FILE
cd /home/ubuntu/mongo-hadoop
sudo -u ubuntu ./gradlew jar
sudo -u ubuntu cp /home/ubuntu/mongo-hadoop/spark/build/libs/mongo-hadoop-spark-*.jar /home/ubuntu/Agile_Data_Code_2/lib/
sudo -u ubuntu cp /home/ubuntu/mongo-hadoop/build/libs/mongo-hadoop-*.jar /home/ubuntu/Agile_Data_Code_2/lib/
cd /home/ubuntu

# Now build the pymongo_spark package
echo "Building the pymongo_spark package ..." | tee -a $LOG_FILE
cd /home/ubuntu/mongo-hadoop/spark/src/main/python
su ubuntu --login -c 'cd /home/ubuntu/mongo-hadoop/spark/src/main/python && python setup.py install'
sudo -u ubuntu cp /home/ubuntu/mongo-hadoop/spark/src/main/python/pymongo_spark.py /home/ubuntu/Agile_Data_Code_2/lib/
export PYTHONPATH=$PYTHONPATH:$PROJECT_HOME/lib
echo "" | sudo tee -a /home/ubuntu/.bash_profile
echo 'export PYTHONPATH=$PYTHONPATH:$PROJECT_HOME/lib' | sudo -u ubuntu tee -a /home/ubuntu/.bash_profile
cd /home/ubuntu

echo "Nuking the source to mongo-hadoop ..." | tee -a $LOG_FILE
sudo -u ubuntu rm -rf /home/ubuntu/mongo-hadoop

#
# Install ElasticSearch in the elasticsearch directory in the root of our project, and the Elasticsearch for Hadoop package
#
echo "curl -sLko /tmp/elasticsearch-5.3.0.tar.gz https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.3.0.tar.gz"
sudo -u ubuntu curl -sLko /tmp/elasticsearch-5.3.0.tar.gz https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.3.0.tar.gz
sudo -u ubuntu mkdir /home/ubuntu/elasticsearch
cd /home/ubuntu
sudo -u ubuntu tar -xvzf /tmp/elasticsearch-5.3.0.tar.gz -C elasticsearch --strip-components=1
sudo -u ubuntu mkdir -p /home/ubuntu/elasticsearch/logs

# Run elasticsearch
sudo -u ubuntu /home/ubuntu/elasticsearch/bin/elasticsearch -d # re-run if you shutdown your computer

# Run a query to test - it will error but should return json
echo "Testing Elasticsearch with a query ..." | tee -a $LOG_FILE
sudo -u ubuntu curl 'localhost:9200/agile_data_science/on_time_performance/_search?q=Origin:ATL&pretty'

# Install Elasticsearch for Hadoop
echo "" | tee -a $LOG_FILE
echo "Installing and configuring Elasticsearch for Hadoop/Spark version 5.5.1 ..." | tee -a $LOG_FILE
sudo -u ubuntu curl -Lko /tmp/elasticsearch-hadoop-6.1.3.zip http://download.elastic.co/hadoop/elasticsearch-hadoop-6.1.3.zip
sudo -u ubuntu unzip /tmp/elasticsearch-hadoop-6.1.3.zip
sudo -u ubuntu mv /home/ubuntu/elasticsearch-hadoop-6.1.3 /home/ubuntu/elasticsearch-hadoop
sudo -u ubuntu cp /home/ubuntu/elasticsearch-hadoop/dist/elasticsearch-hadoop-6.1.3.jar /home/ubuntu/Agile_Data_Code_2/lib/
sudo -u ubuntu cp /home/ubuntu/elasticsearch-hadoop/dist/elasticsearch-spark-20_2.10-6.1.3.jar /home/ubuntu/Agile_Data_Code_2/lib/
echo "spark.speculation false" | sudo -u ubuntu tee -a /home/ubuntu/spark/conf/spark-defaults.conf
sudo -u ubuntu rm -f /tmp/elasticsearch-hadoop-6.1.3.zip
sudo -u ubuntu rm -rf /home/ubuntu/elasticsearch-hadoop/conf/spark-defaults.conf

#
# Spark jar setup
#

# Install and add snappy-java and lzo-java to our classpath below via spark.jars
echo "" | tee -a $LOG_FILE
echo "Installing snappy-java and lzo-java and adding them to our classpath ..." | tee -a $LOG_FILE
cd /home/ubuntu/Agile_Data_Code_2
sudo -u ubuntu curl -Lko lib/snappy-java-1.1.7.1.jar http://central.maven.org/maven2/org/xerial/snappy/snappy-java/1.1.7.1/snappy-java-1.1.7.1.jar
sudo -u ubuntu curl -Lko lib/lzo-hadoop-1.0.5.jar http://central.maven.org/maven2/org/anarres/lzo/lzo-hadoop/1.0.5/lzo-hadoop-1.0.5.jar
cd /home/ubuntu

# Set the spark.jars path
echo "spark.jars /home/ubuntu/Agile_Data_Code_2/lib/mongo-hadoop-spark-2.0.2.jar,/home/ubuntu/Agile_Data_Code_2/lib/mongo-java-driver-3.4.2.jar,/home/ubuntu/Agile_Data_Code_2/lib/mongo-hadoop-2.0.2.jar,/home/ubuntu/Agile_Data_Code_2/lib/elasticsearch-spark-20_2.10-6.1.3.jar,/home/ubuntu/Agile_Data_Code_2/lib/snappy-java-1.1.7.1.jar,/home/ubuntu/Agile_Data_Code_2/lib/lzo-hadoop-1.0.5.jar,/home/ubuntu/Agile_Data_Code_2/lib/commons-httpclient-3.1.jar" | sudo -u ubuntu tee -a /home/ubuntu/spark/conf/spark-defaults.conf

#
# Kafka install and setup
#
echo "" | tee -a $LOG_FILE
echo "Downloading and installing Kafka version 1.0.0 for Spark 2.11 ..." | tee -a $LOG_FILE
sudo -u ubuntu curl -Lko /tmp/kafka_2.11-1.0.0.tgz https://archive.apache.org/dist/kafka/1.0.0/kafka_2.11-1.0.0.tgz
sudo -u ubuntu mkdir -p /home/ubuntu/kafka
cd /home/ubuntu/
sudo -u ubuntu tar -xvzf /tmp/kafka_2.11-1.0.0.tgz -C kafka --strip-components=1 && sudo -u ubuntu rm -f /tmp/kafka_2.11-1.0.0.tgz

# Set the log dir to kafka/logs
echo "Configuring logging for kafka to go into kafka/logs directory ..." | tee -a $LOG_FILE
sudo -u ubuntu sed -i '/log.dirs=\/tmp\/kafka-logs/c\log.dirs=logs' /home/ubuntu/kafka/config/server.properties

# Run zookeeper (which kafka depends on), then Kafka
echo "Running Zookeeper as a daemon ..." | tee -a $LOG_FILE
sudo -H -u ubuntu /home/ubuntu/kafka/bin/zookeeper-server-start.sh -daemon /home/ubuntu/kafka/config/zookeeper.properties
echo "Running Kafka Server as a daemon ..." | tee -a $LOG_FILE
sudo -H -u ubuntu /home/ubuntu/kafka/bin/kafka-server-start.sh -daemon /home/ubuntu/kafka/config/server.properties

#
# Install and setup Airflow
#
echo "" | tee -a $LOG_FILE
echo "Installing Airflow via pip ..." | tee -a $LOG_FILE
su --login ubuntu -c 'pip install apache-airflow[hive]'
sudo -u ubuntu mkdir /home/ubuntu/airflow
sudo -u ubuntu mkdir /home/ubuntu/airflow/dags
sudo -u ubuntu mkdir /home/ubuntu/airflow/logs
sudo -u ubuntu mkdir /home/ubuntu/airflow/plugins

su --login ubuntu -c 'airflow initdb'
su --login ubuntu -c 'airflow webserver -D &'
su --login ubuntu -c 'airflow scheduler -D &'

echo "Adding chown airflow commands to /home/ubuntu/.bash_profile ..." | tee -a $LOG_FILE
echo "sudo chown -R ubuntu /home/ubuntu/airflow" | sudo -u ubuntu tee -a /home/ubuntu/.bash_profile
echo "sudo chgrp -R ubuntu /home/ubuntu/airflow" | sudo -u ubuntu tee -a /home/ubuntu/.bash_profile

# Jupyter server setup
# echo "" | tee -a $LOG_FILE
# echo "Starting Jupyter notebook server ..." | tee -a $LOG_FILE
# jupyter-notebook --generate-config
# cp /home/ubuntu/Agile_Data_Code_2/jupyter_notebook_config.py /home/ubuntu/.jupyter/
# cd /home/ubuntu/Agile_Data_Code_2
# jupyter-notebook --ip=0.0.0.0 &
# cd

# Install Ant to build Cassandra
apt-get install -y ant

# Install Cassandra - must build from source as the latest 3.11.1 build is broken...
echo "" | tee -a $LOG_FILE
echo "Installing Cassandra ..."
sudo -u ubuntu git clone https://github.com/apache/cassandra
cd cassandra
su --login ubuntu -c 'cd /home/ubuntu/cassandra && git checkout cassandra-3.11'
su --login ubuntu -c 'cd /home/ubuntu/cassandra && ant'
sudo -u ubuntu bin/cassandra
export PATH=$PATH:/home/ubuntu/cassandra/bin
echo 'export PATH=$PATH:/home/ubuntu/cassandra/bin' | sudo -u ubuntu tee -a /home/ubuntu/.bash_profile
cd ..

# Install and setup JanusGraph
echo "" | tee -a $LOG_FILE
echo "Installing JanusGraph ..." | tee -a $LOG_FILE
cd
sudo -u ubuntu curl -Lko /tmp/janusgraph-0.2.0-hadoop2.zip \
  https://github.com/JanusGraph/janusgraph/releases/download/v0.2.0/janusgraph-0.2.0-hadoop2.zip
sudo -u ubuntu unzip -d . /tmp/janusgraph-0.2.0-hadoop2.zip
sudo -u ubuntu mv janusgraph-0.2.0-hadoop2 janusgraph
sudo -u ubuntu rm /tmp/janusgraph-0.2.0-hadoop2.zip

#
# Cleanup
#
echo "Cleaning up after our selves ..." | tee -a $LOG_FILE
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
