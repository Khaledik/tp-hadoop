#!/bin/bash

HOSTNAME=$(hostname)
ROLE=${ROLE:-slave}

HADOOP_HOME=${HADOOP_HOME:-/opt/hadoop}
HBASE_HOME=${HBASE_HOME:-/opt/hbase}
ZK_HOME=${ZK_HOME:-/opt/zookeeper}

# Resolve JAVA_HOME: honour the symlink created in the Dockerfile, or fall
# back to architecture detection so the cluster works on both amd64 and arm64
# (Apple Silicon Macs).
if [ ! -d "$JAVA_HOME" ]; then
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk-$(dpkg --print-architecture)
    export JAVA_HOME
fi
HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
HBASE_CONF_DIR=$HBASE_HOME/conf

export JAVA_HOME HADOOP_HOME HBASE_HOME ZK_HOME HADOOP_CONF_DIR HBASE_CONF_DIR
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HBASE_HOME/bin:$ZK_HOME/bin
export ZK_SERVER_HEAP=${ZK_SERVER_HEAP:-128}
export SERVER_JVMFLAGS="-Xms${ZK_SERVER_HEAP}m -Xmx${ZK_SERVER_HEAP}m"

# ── System ────────────────────────────────────────────────────

setup_hosts() {
    cat > /etc/hosts <<-EOF
127.0.0.1  localhost
172.30.0.10 hadoop-master
172.30.0.20 hadoop-slave1
172.30.0.30 hadoop-slave2
EOF
}

start_ssh() {
    if [ ! -f /var/run/sshd/sshd.pid ]; then
        /usr/sbin/sshd
    fi
}

setup_hadoop_profile() {
    mkdir -p /tmp/hadoop
    cat > /etc/profile.d/hadoop.sh <<-EOF
export JAVA_HOME=$JAVA_HOME
export HADOOP_HOME=$HADOOP_HOME
export HBASE_HOME=$HBASE_HOME
export ZK_HOME=$ZK_HOME
export HIVE_HOME=$HIVE_HOME
export HADOOP_CONF_DIR=$HADOOP_CONF_DIR
export HBASE_CONF_DIR=$HBASE_CONF_DIR
export PATH=\$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HBASE_HOME/bin:$ZK_HOME/bin:$HIVE_HOME/bin
EOF
    chmod +x /etc/profile.d/hadoop.sh
}

# ── SSH config (non-keys) ─────────────────────────────────────

setup_ssh_config() {
    sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config 2>/dev/null
    grep -q "StrictHostKeyChecking no" /etc/ssh/ssh_config || \
        echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config
    grep -q "UserKnownHostsFile /dev/null" /etc/ssh/ssh_config || \
        echo "UserKnownHostsFile /dev/null" >> /etc/ssh/ssh_config
}

# ── Hadoop env tweaks (heaps) ─────────────────────────────────

setup_hadoop_heaps() {
    # Idempotent : le bloc est réécrit à chaque démarrage (le conteneur peut
    # redémarrer et le cat >> ne doit pas dupliquer les exports).
    sed -i '/# --- cluster-heaps (added by entrypoint) ---/,/# --- fin cluster-heaps ---/d' $HADOOP_CONF_DIR/hadoop-env.sh
    cat >> $HADOOP_CONF_DIR/hadoop-env.sh <<-EOF
# --- cluster-heaps (added by entrypoint) ---
export JAVA_HOME=$JAVA_HOME
export HADOOP_HOME=$HADOOP_HOME
export HADOOP_CONF_DIR=$HADOOP_CONF_DIR
export HADOOP_HEAPSIZE=\${HADOOP_HEAPSIZE:-192}
export HADOOP_METASPACE_MAX=\${HADOOP_METASPACE_MAX:-64m}
export HADOOP_OPTS="--add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.lang.reflect=ALL-UNNAMED -XX:MaxMetaspaceSize=\${HADOOP_METASPACE_MAX:-64m} -Xss512k"
export HDFS_NAMENODE_OPTS="-Xms192m -Xmx192m"
export HDFS_DATANODE_OPTS="-Xms128m -Xmx128m"
export HDFS_SECONDARYNAMENODE_OPTS="-Xms192m -Xmx192m"
# --- fin cluster-heaps ---
EOF

    cat >> $HADOOP_CONF_DIR/yarn-env.sh <<-EOF
export YARN_RESOURCEMANAGER_OPTS="-Xms192m -Xmx192m"
export YARN_NODEMANAGER_OPTS="-Xms128m -Xmx128m"
export YARN_HEAPSIZE=192
EOF

    cat >> $HBASE_CONF_DIR/hbase-env.sh <<-EOF
export JAVA_HOME=$JAVA_HOME
export HBASE_HEAPSIZE=192
export HBASE_MASTER_OPTS="-Xms192m -Xmx192m"
export HBASE_REGIONSERVER_OPTS="-Xms192m -Xmx192m"
export HBASE_THRIFT_OPTS="-Xms128m -Xmx128m"
export HBASE_OPTS="--add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.lang.reflect=ALL-UNNAMED --add-opens java.base/java.util=ALL-UNNAMED -XX:MaxMetaspaceSize=96m -Xss512k"
EOF
}

# ── Permissions ────────────────────────────────────────────────
# Les bind mounts (./scripts/master → /home, ./src → /home/src) propagent
# le mode des fichiers du host. Sous Windows, Git stocke les .sh en 644
# (sans bit x), donc les scripts montés ne sont pas exécutables dans le
# conteneur. On force le bit x ici, après montage, à chaque démarrage.

fix_permissions() {
    chmod 744 /home/*.sh 2>/dev/null
    chmod 744 /home/src/wordcount/*.sh 2>/dev/null
    chmod 744 /opt/scripts/entrypoint.sh 2>/dev/null
}

# ── Cleanup ───────────────────────────────────────────────────

cleanup() {
    echo "[INFO] Container stopped."
    exit 0
}

# ── Main ──────────────────────────────────────────────────────

trap cleanup SIGTERM SIGINT

setup_hosts
start_ssh
setup_ssh_config
setup_hadoop_profile
setup_hadoop_heaps
fix_permissions

if [ "$ROLE" = "master" ]; then
    echo "[INFO] Initializing ZooKeeper myid..."
    echo "1" > /data/zookeeper/myid

    echo "[INFO] Formatting HDFS NameNode (first run only)..."
    if [ ! -f /data/hdfs/namenode/current/VERSION ]; then
        $HADOOP_HOME/bin/hdfs namenode -format -force -nonInteractive
    fi
fi

echo "[INFO] Container ready. Role: $ROLE"

while true; do
    sleep 30
done
