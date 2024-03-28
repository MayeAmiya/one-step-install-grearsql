#!/bin/bash
# 自动安装GreatSQL到CentOS中
# Author: MayeKo
# Date: 2024/03/16
# Version: 0.9


echo "开始执行脚本"

echo "更新文件"

rm -f /etc/yum.repos.d/centos.repo
rm -f /etc/yum.repos.d/centos-addons.repo

touch /etc/yum.repos.d/centos.repo
    if [ $? -ne 0 ]; then
        echo "更新文件失败"
        exit 1
    fi

echo '[baseos]' >> /etc/yum.repos.d/centos.repo
echo 'name=CentOS Stream $releasever - BaseOS' >> /etc/yum.repos.d/centos.repo
echo '#mirrorlist=http://mirrorlist.centos.org/?release=$stream&arch=$basearch&repo=BaseOS&infra=$infra' >> /etc/yum.repos.d/centos.repo
echo 'baseurl=https://mirrors.ustc.edu.cn/centos-stream/9-stream/BaseOS/$basearch/os/' >> /etc/yum.repos.d/centos.repo
echo 'gpgcheck=1' >> /etc/yum.repos.d/centos.repo
echo 'enabled=1' >> /etc/yum.repos.d/centos.repo
echo 'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial' >> /etc/yum.repos.d/centos.repo
echo '[appstream]' >> /etc/yum.repos.d/centos.repo
echo 'name=CentOS Stream $releasever - AppStream' >> /etc/yum.repos.d/centos.repo
echo '#mirrorlist=http://mirrorlist.centos.org/?release=$stream&arch=$basearch&repo=AppStream&infra=$infra' >> /etc/yum.repos.d/centos.repo
echo 'baseurl=https://mirrors.ustc.edu.cn/centos-stream/9-stream/AppStream/$basearch/os/' >> /etc/yum.repos.d/centos.repo
echo 'gpgcheck=1' >> /etc/yum.repos.d/centos.repo
echo 'enabled=1' >> /etc/yum.repos.d/centos.repo
echo 'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial' >> /etc/yum.repos.d/centos.repo

yum clean all
yum makecache
yum update

    if [ $? -ne 0 ]; then
        echo "换源失败"
        exit 1
    fi
echo "换源完毕"

if [ -f "/usr/local/GreatSQL-8.0.32-25-Linux-glibc2.28-x86_64.tar.xz" ]; then
    tar xf /usr/local/GreatSQL-8.0.32-25-Linux-glibc2.28-x86_64.tar.xz -C /usr/local/
    if [ $? -ne 0 ]; then
        rm -f /usr/local/GreatSQL-8.0.32-25-Linux-glibc2.28-x86_64.tar.xz
        echo "压缩文件损坏,请重新执行脚本"
        exit 1
    fi
else
    echo "安装数据库开始,如果失败多安装几次"
    curl -o /usr/local/GreatSQL-8.0.32-25-Linux-glibc2.28-x86_64.tar.xz https://product.greatdb.com/GreatSQL-8.0.32-25-Rapid/GM/GreatSQL-8.0.32-25-Linux-glibc2.28-x86_64.tar.xz

    if [ $? -ne 0 ]; then
        echo "安装数据库失败,请手动执行如下指令后再运行脚本"
        echo "curl -o /usr/local/GreatSQL-8.0.32-25-Linux-glibc2.28-x86_64.tar.xz https://product.greatdb.com/GreatSQL-8.0.32-25-Rapid/GM/GreatSQL-8.0.32-25-Linux-glibc2.28-x86_64.tar.xz"
        exit 1
    fi

    tar xf /usr/local/GreatSQL-8.0.32-25-Linux-glibc2.28-x86_64.tar.xz -C /usr/local/
fi

if [ -f "~/.bash_profile" ] &&  grep -q "'export PATH=/usr/local/GreatSQL-8.0.32-25-Linux-glibc2.28-x86_64/bin:$PATH'" "~/.bash_profile"; then
    echo "PATH存在"
else
    echo 'export PATH=/usr/local/GreatSQL-8.0.32-25-Linux-glibc2.28-x86_64/bin:$PATH' >> ~/.bash_profile
    source ~/.bash_profile
fi

echo "安装数据库完毕"

echo "安装依赖开始"

yum install -y pkg-config perl libaio-devel numactl-devel numactl-libs net-tools openssl openssl-devel perl-Data-Dumper perl-Digest-MD5 gcc gcc-c++ vim git

echo "安装依赖完毕"

echo "设置用户开始"

/sbin/groupadd mysql
/sbin/useradd -g mysql mysql -d /dev/null -s /sbin/nologin

mkdir -p /home/root/data/GreatSQL
chown -R mysql:mysql /home/root/data/GreatSQL
chmod -R 700 /home/root/data/GreatSQL

echo "设置用户完毕"

echo "写入配置开始"

if [ -f "/etc/my.cnf" ] &&  grep -q "[client]" "/etc/my.cnf"; then
    # 检查文件中是否存在特定语句
    echo "配置存在"
else
    echo '[client]' >> /etc/my.cnf
    echo 'user = root' >> /etc/my.cnf
    echo 'socket = /home/root/data/GreatSQL/mysql.sock' >> /etc/my.cnf
    echo '[client] '
    echo 'user = root' 
    echo 'socket = /home/root/data/GreatSQL/mysql.sock' 
    echo '' >> /etc/my.cnf
    echo '[mysqld]' >> /etc/my.cnf
    echo 'user	= mysql' >> /etc/my.cnf
    echo 'port	= 3306' >> /etc/my.cnf
    echo '[mysqld]'
    echo 'user	= mysql'
    echo 'port	= 3306' 
    echo '#主从复制或MGR集群中，server_id记得要不同' >> /etc/my.cnf
    echo '#另外，实例启动时会生成 auto.cnf，里面的 server_uuid 值也要不同' >> /etc/my.cnf
    echo '#server_uuid的值还可以自己手动指定，只要符合uuid的格式标准就可以' >> /etc/my.cnf
    echo 'server_id = 3306' >> /etc/my.cnf
    echo 'basedir = /usr/local/GreatSQL-8.0.32-25-Linux-glibc2.28-x86_64' >> /etc/my.cnf
    echo 'datadir	= /home/root/data/GreatSQL' >> /etc/my.cnf
    echo 'socket	= /home/root/data/GreatSQL/mysql.sock' >> /etc/my.cnf
    echo 'basedir = /usr/local/GreatSQL-8.0.32-25-Linux-glibc2.28-x86_64' 
    echo 'datadir	= /home/root/data/GreatSQL' 
    echo 'socket	= /home/root/data/GreatSQL/mysql.sock' 
    echo 'pid-file = mysql.pid' >> /etc/my.cnf
    echo 'character-set-server = UTF8MB4' >> /etc/my.cnf
    echo 'skip_name_resolve = 1' >> /etc/my.cnf
    echo '#若你的MySQL数据库主要运行在境外，请务必根据实际情况调整本参数' >> /etc/my.cnf
    echo 'default_time_zone = "+8:00"' >> /etc/my.cnf
    echo '' >> /etc/my.cnf
    echo '#performance setttings' >> /etc/my.cnf
    echo 'lock_wait_timeout = 3600' >> /etc/my.cnf
    echo 'open_files_limit    = 65535' >> /etc/my.cnf
    echo 'back_log = 1024' >> /etc/my.cnf
    echo 'max_connections = 512' >> /etc/my.cnf
    echo 'max_connect_errors = 1000000' >> /etc/my.cnf
    echo '' >> /etc/my.cnf
    echo 'table_open_cache = 1024' >> /etc/my.cnf
    echo 'table_definition_cache = 1024' >> /etc/my.cnf
    echo 'thread_stack = 512K' >> /etc/my.cnf
    echo 'sort_buffer_size = 4M' >> /etc/my.cnf
    echo 'join_buffer_size = 4M' >> /etc/my.cnf
    echo 'read_buffer_size = 8M' >> /etc/my.cnf
    echo 'read_rnd_buffer_size = 4M' >> /etc/my.cnf
    echo 'bulk_insert_buffer_size = 64M' >> /etc/my.cnf
    echo 'thread_cache_size = 768' >> /etc/my.cnf
    echo 'interactive_timeout = 600' >> /etc/my.cnf
    echo 'wait_timeout = 600' >> /etc/my.cnf
    echo 'tmp_table_size = 32M' >> /etc/my.cnf
    echo 'max_heap_table_size = 32M' >> /etc/my.cnf
    echo 'max_allowed_packet = 64M' >> /etc/my.cnf
    echo 'net_buffer_shrink_interval = 180' >> /etc/my.cnf
    echo '#GIPK' >> /etc/my.cnf
    echo 'loose-sql_generate_invisible_primary_key = ON' >> /etc/my.cnf
    echo '' >> /etc/my.cnf
    echo '#log settings' >> /etc/my.cnf
    echo 'log_timestamps = SYSTEM' >> /etc/my.cnf
    echo 'log_error = error.log' >> /etc/my.cnf
    echo 'log_error_verbosity = 3' >> /etc/my.cnf
    echo 'slow_query_log = 1' >> /etc/my.cnf
    echo 'log_slow_extra = 1' >> /etc/my.cnf
    echo 'slow_query_log_file = slow.log' >> /etc/my.cnf
    echo '#设置slow log文件大小1G及总文件数10' >> /etc/my.cnf
    echo 'max_slowlog_size = 1073741824' >> /etc/my.cnf
    echo 'max_slowlog_files = 10' >> /etc/my.cnf
    echo 'long_query_time = 0.1' >> /etc/my.cnf
    echo 'log_queries_not_using_indexes = 1' >> /etc/my.cnf
    echo 'log_throttle_queries_not_using_indexes = 60' >> /etc/my.cnf
    echo 'min_examined_row_limit = 100' >> /etc/my.cnf
    echo 'log_slow_admin_statements = 1' >> /etc/my.cnf
    echo 'log_slow_slave_statements = 1' >> /etc/my.cnf
    echo 'log_bin = binlog' >> /etc/my.cnf
    echo 'binlog_format = ROW' >> /etc/my.cnf
    echo 'sync_binlog = 1' >> /etc/my.cnf
    echo 'binlog_cache_size = 4M' >> /etc/my.cnf
    echo 'max_binlog_cache_size = 2G' >> /etc/my.cnf
    echo 'max_binlog_size = 1G' >> /etc/my.cnf
    echo '#控制binlog总大小，避免磁盘空间被撑爆' >> /etc/my.cnf
    echo 'binlog_space_limit = 500G' >> /etc/my.cnf
    echo 'binlog_rows_query_log_events = 1' >> /etc/my.cnf
    echo 'binlog_expire_logs_seconds = 604800' >> /etc/my.cnf
    echo '#MySQL 8.0.22前，想启用MGR的话，需要设置binlog_checksum=NONE才行' >> /etc/my.cnf
    echo 'binlog_checksum = CRC32' >> /etc/my.cnf
    echo 'gtid_mode = ON' >> /etc/my.cnf
    echo 'enforce_gtid_consistency = TRUE' >> /etc/my.cnf
    echo '' >> /etc/my.cnf
    echo '#myisam settings' >> /etc/my.cnf
    echo 'key_buffer_size = 32M' >> /etc/my.cnf
    echo 'myisam_sort_buffer_size = 128M' >> /etc/my.cnf
    echo '' >> /etc/my.cnf
    echo '#replication settings' >> /etc/my.cnf
    echo 'relay_log_recovery = 1' >> /etc/my.cnf
    echo 'slave_parallel_type = LOGICAL_CLOCK' >> /etc/my.cnf
    echo '#可以设置为逻辑CPU数量的2倍' >> /etc/my.cnf
    echo 'slave_parallel_workers = 64' >> /etc/my.cnf
    echo 'binlog_transaction_dependency_tracking = WRITESET' >> /etc/my.cnf
    echo 'slave_preserve_commit_order = 1' >> /etc/my.cnf
    echo 'slave_checkpoint_period = 2' >> /etc/my.cnf
    echo '' >> /etc/my.cnf
    echo '#mgr settings' >> /etc/my.cnf
    echo 'loose-plugin_load_add = 'mysql_clone.so'' >> /etc/my.cnf
    echo 'loose-plugin_load_add = 'group_replication.so'' >> /etc/my.cnf
    echo 'loose-group_replication_group_name = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1"' >> /etc/my.cnf
    echo '#MGR本地节点IP:PORT，请自行替换' >> /etc/my.cnf
    echo 'loose-group_replication_local_address = "172.16.16.10:33061"' >> /etc/my.cnf
    echo '#MGR集群所有节点IP:PORT，请自行替换' >> /etc/my.cnf
    echo 'loose-group_replication_group_seeds = "172.16.16.10:33061,172.16.16.11:33061,172.16.16.12:33061"' >> /etc/my.cnf
    echo 'loose-group_replication_start_on_boot = OFF' >> /etc/my.cnf
    echo 'loose-group_replication_bootstrap_group = OFF' >> /etc/my.cnf
    echo 'loose-group_replication_exit_state_action = READ_ONLY' >> /etc/my.cnf
    echo 'loose-group_replication_flow_control_mode = "DISABLED"' >> /etc/my.cnf
    echo 'loose-group_replication_single_primary_mode = ON' >> /etc/my.cnf
    echo 'loose-group_replication_majority_after_mode = ON' >> /etc/my.cnf
    echo 'loose-group_replication_communication_max_message_size = 10M' >> /etc/my.cnf
    echo 'loose-group_replication_arbitrator = 0' >> /etc/my.cnf
    echo 'loose-group_replication_single_primary_fast_mode = 1' >> /etc/my.cnf
    echo 'loose-group_replication_request_time_threshold = 100' >> /etc/my.cnf
    echo 'loose-group_replication_primary_election_mode = GTID_FIRST' >> /etc/my.cnf
    echo 'loose-group_replication_unreachable_majority_timeout = 0' >> /etc/my.cnf
    echo 'loose-group_replication_member_expel_timeout = 5' >> /etc/my.cnf
    echo 'loose-group_replication_autorejoin_tries = 288' >> /etc/my.cnf
    echo 'report_host = "172.16.16.10"' >> /etc/my.cnf
    echo '' >> /etc/my.cnf
    echo '#innodb settings' >> /etc/my.cnf
    echo 'innodb_buffer_pool_size = 2G' >> /etc/my.cnf
    echo 'innodb_buffer_pool_instances = 8' >> /etc/my.cnf
    echo 'innodb_data_file_path = ibdata1:12M:autoextend' >> /etc/my.cnf
    echo 'innodb_flush_log_at_trx_commit = 1' >> /etc/my.cnf
    echo 'innodb_log_buffer_size = 32M' >> /etc/my.cnf
    echo 'innodb_log_file_size = 2G' >> /etc/my.cnf
    echo 'innodb_log_files_in_group = 3' >> /etc/my.cnf
    echo 'innodb_redo_log_capacity = 6G' >> /etc/my.cnf
    echo 'innodb_max_undo_log_size = 4G' >> /etc/my.cnf
    echo '# 根据您的服务器IOPS能力适当调整' >> /etc/my.cnf
    echo '# 一般配普通SSD盘的话，可以调整到 10000 - 20000' >> /etc/my.cnf
    echo '# 配置高端PCIe SSD卡的话，则可以调整的更高，比如 50000 - 80000' >> /etc/my.cnf
    echo 'innodb_io_capacity = 4000' >> /etc/my.cnf
    echo 'innodb_io_capacity_max = 8000' >> /etc/my.cnf
    echo 'innodb_open_files = 65535' >> /etc/my.cnf
    echo 'innodb_flush_method = O_DIRECT' >> /etc/my.cnf
    echo 'innodb_lru_scan_depth = 4000' >> /etc/my.cnf
    echo 'innodb_lock_wait_timeout = 10' >> /etc/my.cnf
    echo 'innodb_rollback_on_timeout = 1' >> /etc/my.cnf
    echo 'innodb_print_all_deadlocks = 1' >> /etc/my.cnf
    echo 'innodb_online_alter_log_max_size = 4G' >> /etc/my.cnf
    echo 'innodb_print_ddl_logs = 0' >> /etc/my.cnf
    echo 'innodb_status_file = 1' >> /etc/my.cnf
    echo '#注意: 开启 innodb_status_output & innodb_status_output_locks 后, 可能会导致log_error文件增长较快' >> /etc/my.cnf
    echo 'innodb_status_output = 0' >> /etc/my.cnf
    echo 'innodb_status_output_locks = 1' >> /etc/my.cnf
    echo 'innodb_sort_buffer_size = 67108864' >> /etc/my.cnf
    echo 'innodb_adaptive_hash_index = 0' >> /etc/my.cnf
    echo '#开启NUMA支持' >> /etc/my.cnf
    echo 'innodb_numa_interleave = ON' >> /etc/my.cnf
    echo 'innodb_print_lock_wait_timeout_info = 1' >> /etc/my.cnf
    echo '#自动杀掉超过5分钟不活跃事务，避免行锁被长时间持有 ' >> /etc/my.cnf
    echo 'kill_idle_transaction = 300' >> /etc/my.cnf
    echo '' >> /etc/my.cnf
    echo '#innodb monitor settings' >> /etc/my.cnf
    echo '#innodb_monitor_enable = "module_innodb,module_server,module_dml,module_ddl,module_trx,module_os,module_purge,module_log,module_lock,module_buffer,module_index,module_ibuf_system,module_buffer_page,module_adaptive_hash" ' >> /etc/my.cnf
    echo '' >> /etc/my.cnf
    echo '#innodb parallel query' >> /etc/my.cnf
    echo 'loose-force_parallel_execute = OFF' >> /etc/my.cnf
    echo 'loose-parallel_default_dop = 8' >> /etc/my.cnf
    echo 'loose-parallel_max_threads = 96' >> /etc/my.cnf
    echo 'temptable_max_ram = 8G' >> /etc/my.cnf
    echo '' >> /etc/my.cnf
    echo '#pfs settings' >> /etc/my.cnf
    echo 'performance_schema = 1' >> /etc/my.cnf
    echo '#performance_schema_instrument = '%memory%=on' ' >> /etc/my.cnf
    echo 'performance_schema_instrument = '%lock%=on' ' >> /etc/my.cnf
    echo "写入配置完毕"

fi


echo "写入服务开始"

if [ -f "/etc/my.cnf" ] &&  grep -q "[Unit]" "/lib/systemd/system/greatsql.service"; then
    # 检查文件中是否存在特定语句
    echo "配置存在"
else
    touch /lib/systemd/system/greatsql.service
    echo '[Unit] ' >> /lib/systemd/system/greatsql.service
    echo 'Description=GreatSQL Server' >> /lib/systemd/system/greatsql.service
    echo 'Documentation=man:mysqld(8)' >> /lib/systemd/system/greatsql.service
    echo 'Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html' >> /lib/systemd/system/greatsql.service
    echo 'After=network.target' >> /lib/systemd/system/greatsql.service
    echo 'After=syslog.target' >> /lib/systemd/system/greatsql.service
    echo '[Install]' >> /lib/systemd/system/greatsql.service
    echo 'WantedBy=multi-user.target' >> /lib/systemd/system/greatsql.service
    echo '[Service]' >> /lib/systemd/system/greatsql.service
    echo '' >> /lib/systemd/system/greatsql.service
    echo '# some limits' >> /lib/systemd/system/greatsql.service
    echo '# file size' >> /lib/systemd/system/greatsql.service
    echo 'LimitFSIZE=infinity' >> /lib/systemd/system/greatsql.service
    echo '# cpu time' >> /lib/systemd/system/greatsql.service
    echo 'LimitCPU=infinity' >> /lib/systemd/system/greatsql.service
    echo '# virtual memory size' >> /lib/systemd/system/greatsql.service
    echo 'LimitAS=infinity' >> /lib/systemd/system/greatsql.service
    echo '# open files' >> /lib/systemd/system/greatsql.service
    echo 'LimitNOFILE=65535' >> /lib/systemd/system/greatsql.service
    echo '# processes/threads' >> /lib/systemd/system/greatsql.service
    echo 'LimitNPROC=65535' >> /lib/systemd/system/greatsql.service
    echo '# locked memory' >> /lib/systemd/system/greatsql.service
    echo 'LimitMEMLOCK=infinity' >> /lib/systemd/system/greatsql.service
    echo '# total threads (user+kernel)' >> /lib/systemd/system/greatsql.service
    echo 'TasksMax=infinity' >> /lib/systemd/system/greatsql.service
    echo 'TasksAccounting=false' >> /lib/systemd/system/greatsql.service
    echo '' >> /lib/systemd/system/greatsql.service
    echo 'User=mysql' >> /lib/systemd/system/greatsql.service
    echo 'Group=mysql' >> /lib/systemd/system/greatsql.service
    echo '#如果是GreatSQL 5.7版本，此处需要改成simple模式，否则可能服务启用异常' >> /lib/systemd/system/greatsql.service
    echo '#如果是GreatSQL 8.0版本则可以使用notify模式' >> /lib/systemd/system/greatsql.service
    echo '#Type=simple' >> /lib/systemd/system/greatsql.service
    echo 'Type=notify' >> /lib/systemd/system/greatsql.service
    echo 'TimeoutSec=0' >> /lib/systemd/system/greatsql.service
    echo 'PermissionsStartOnly=true' >> /lib/systemd/system/greatsql.service
    echo 'ExecStartPre=/usr/local/GreatSQL-8.0.32-25-Linux-glibc2.28-x86_64/bin/mysqld_pre_systemd' >> /lib/systemd/system/greatsql.service
    echo 'ExecStart=/usr/local/GreatSQL-8.0.32-25-Linux-glibc2.28-x86_64/bin/mysqld $MYSQLD_OPTS' >> /lib/systemd/system/greatsql.service
    echo 'EnvironmentFile=-/etc/sysconfig/mysql' >> /lib/systemd/system/greatsql.service
    echo 'Restart=on-failure' >> /lib/systemd/system/greatsql.service
    echo 'RestartPreventExitStatus=1' >> /lib/systemd/system/greatsql.service
    echo 'Environment=MYSQLD_PARENT_PID=1' >> /lib/systemd/system/greatsql.service
    echo 'PrivateTmp=false' >> /lib/systemd/system/greatsql.service
fi

mysqld --initialize-insecure

systemctl daemon-reload

systemctl enable greatsql
systemctl start greatsql
if [ $? -ne 0 ]; then
    rm -f /usr/local/GreatSQL-8.0.32-25-Linux-glibc2.28-x86_64.tar.xz
fi

systemctl status greatsql

echo "写入服务完毕,请重启"

