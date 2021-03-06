
source .env

echo "run on hmaster only"

# todo: design fully distributed arch. here
# contains internal env variables !
HBASE_HOME=/home/hadoop/hbase-2.2.3

HMASTER_NODE=${INSTANCE_NAMES[9]}
BACKUP_HMASTERS=(${INSTANCE_NAMES[10]})
REGION_SERVERS=(${INSTANCE_NAMES[11]} ${INSTANCE_NAMES[12]})
ZK_NODE=(${INSTANCE_NAMES[@]:4:5})
HBASE_PATH=(/data-1)

# STEP: backup
echo "backup conf. files"
cp ${HBASE_HOME}/conf/hbase-env.sh ${HBASE_HOME}/conf/hbase-env-backup.sh
cp ${HBASE_HOME}/conf/hbase-site.xml ${HBASE_HOME}/conf/hbase-site-backup.xml


# STEP: configuration
echo "configurations of HBASE"

echo export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java)))) >> ${HBASE_HOME}/conf/hbase-env.sh
echo export HBASE_LOG_DIR=${HBASE_PATH}/logs >> ${HBASE_HOME}/conf/hbase-env.sh
echo export HBASE_MANAGES_ZK=false >> ${HBASE_HOME}/conf/hbase-env.sh

cat > ${HBASE_HOME}/conf/hbase-site.xml <<EOL
<configuration>

<!--master-->
    <property>
        <name>hbase.cluster.distributed</name>
        <value>true</value>
    </property>

    <property>
        <name>hbase.rootdir</name>
        <value>hdfs://name-node:9000/hbase</value>
    </property>

    <property>
        <name>hbase.zookeeper.quorum</name>
        <value>${ZK_NODE[0]},${ZK_NODE[1]},${ZK_NODE[2]},${ZK_NODE[3]},${ZK_NODE[4]}</value>
    </property>

    <property>
        <name>hbase.zookeeper.property.clientPort</name>
        <value>2181</value>
    </property>
<!--
    <property>
        <name>hbase.unsafe.stream.capability.enforce</name>
        <value>true</value>
    </property>
-->

<!--secondaryMaster-->


<!--worker-->

</configuration>
EOL

# put only regionServers' machines
cat > ${HBASE_HOME}/conf/regionservers <<EOL
${REGION_SERVERS[0]}
${REGION_SERVERS[1]}
EOL

# put only backup masters' machines
cat > ${HBASE_HOME}/conf/backup-masters <<EOL
${BACKUP_HMASTERS[0]}
EOL

# STEP: distribute
echo "distribute conf. files to all except master"

for i in $(seq 10 1 3) 
do

  scp ${HBASE_HOME}/conf/* hadoop@${INSTANCE_NAMES[i]}:${HBASE_HOME}/conf/
done

echo "HBASE_HOME=$HBASE_HOME"
echo "Run ${HBASE_HOME}/bin/start-hbase.sh to start hbase"