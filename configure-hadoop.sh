# run on compute engine


# adds below lines into same file
echo export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java)))) >> ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh
echo export HADOOP_HOME=${HADOOP_HOME} >> ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh
echo export HADOOP_LOG_DIR=/hdfs/logs >> ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh


# add hostname and IPs
index=1
for i in `gcloud compute addresses list | grep '\n' | awk '{$1=""; print $2}'`
do
  echo ${i} machine-${index} | sudo tee -a /etc/hosts
  let index=${index}+1
done

# creates as new file
cat > ${HADOOP_HOME}/etc/hadoop/core-site.xml <<EOL
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://$(gcloud compute instances describe $(curl -H Metadata-Flavor:Google http://metadata/computeMetadata/v1/instance/name) --format='get(networkInterfaces[0].accessConfigs[0].natIP)' --zone=europe-west4-a):9000</value>
    </property>
</configuration>
EOL

# creates as new file
cat > ${HADOOP_HOME}/etc/hadoop/hdfs-site.xml <<EOL
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
</configuration>
EOL

# todo:  check => ./hadoop-3.2.1/bin/hadoop version

# format for the first time
${HADOOP_HOME}/bin/hdfs namenode -format