#!/bin/bash
cat <<EOF > /etc/mysql/mysql.conf.d/group-replication.cnf
[mysqld]
#====== Storage Engines Settings ======#
# 组复制只能用innoDB, 为避免误用, 把其它存储引擎禁掉
disabled_storage_engines="MyISAM,BLACKHOLE,FEDERATED,ARCHIVE,MEMORY"

#====== Replication Framework Settings ======#
server_id=1
gtid_mode=ON
enforce_gtid_consistency=ON

# MySQL 8.0.20 之前不支持binlog_chekcsum, 需要关掉
binlog_checksum=NONE

# Replica 也记 binlog, 可以实现 A->B->C 这样的复制链
log_replica_updates=ON
log_bin=binlog
binlog_format=row

#====== Group Replication Settings ======#
# TODO
plugin_load_add='group_replication.so'

# use SELECT UUID() to generate a UUID
group_replication_group_name="aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"

# Group Replication internal communication address
group_replication_local_address= "192.168.3.4:33061"

report_host="192.168.13.4"

# all Group Replication member's address
group_replication_group_seeds= "192.168.3.3:33061,192.168.3.4:33061,192.168.3.6:33061"

# Must only be enabled on one server instance belonging to a group at any time
# If you bootstrap the group multiple times when multiple server instances have this option set,
# they could create an artificial split brain scenario, 
# in which two distinct groups with the same name exist. 
group_replication_bootstrap_group=OFF



#====== Group Replication Settings ======#
# 默认单主, 改为OFF就是多主。切换函数:
# group_replication_switch_to_single_primary_mode() 
# group_replication_switch_to_multi_primary_mode() 
# 将当前访问切换为主: group_replication_set_as_primary()
group_replication_single_primary_mode=ON

# 单主模式时本配置必须为OFF
group_replication_enforce_update_everywhere_checks=OFF

#
group_replication_consistency=BEFORE_ON_PRIMARY_FAILOVER 
EOF

systemctl restart mysql

mysql -e "\
SET SQL_LOG_BIN=0;\
CREATE USER IF NOT EXISTS rpl_user@'%' IDENTIFIED BY '123456';\
GRANT REPLICATION SLAVE ON *.* TO rpl_user@'%';\
GRANT CONNECTION_ADMIN ON *.* TO rpl_user@'%';\
GRANT BACKUP_ADMIN ON *.* TO rpl_user@'%';\
GRANT GROUP_REPLICATION_STREAM ON *.* TO rpl_user@'%';\
FLUSH PRIVILEGES;\
SET SQL_LOG_BIN=1;\
"

mysql -e "CHANGE REPLICATION SOURCE TO SOURCE_USER='rpl_user', SOURCE_PASSWORD='123456' FOR CHANNEL 'group_replication_recovery'"