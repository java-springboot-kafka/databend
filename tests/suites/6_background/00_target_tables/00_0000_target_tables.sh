#!/usr/bin/env bash

CURDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$CURDIR"/../../../shell_env.sh

# Should be <root>/tests/data/
DATADIR=$(realpath $CURDIR/../../../data/)
echo "drop table if exists target1;" | $BENDSQL_CLIENT_CONNECT
echo "drop table if exists target2" | $BENDSQL_CLIENT_CONNECT

## Create table
echo "create table target1(i int);" | $BENDSQL_CLIENT_CONNECT

current_time=$(date -u +"%Y-%m-%d %H:%M:%S.%N")
encoded_time=$(date -u +"%Y-%m-%dT%H:%M:%S.%NZ")
echo "select * from system.processes where type != 'HTTPQuery';" | $BENDSQL_CLIENT_CONNECT

echo "select st.name bt,type, bt.trigger from system.background_tasks AS bt JOIN system.tables st ON bt.table_id = st.table_id where bt.trigger is not null and bt.created_on > TO_TIMESTAMP('$current_time') order by st.name;" | $BENDSQL_CLIENT_CONNECT
echo "call  system\$execute_background_job('test_tenant-compactor-job');"
echo "call  system\$execute_background_job('test_tenant-compactor-job');" | $BENDSQL_CLIENT_CONNECT
sleep 1
echo "select st.name bt,type, bt.trigger from system.background_tasks AS bt JOIN system.tables st ON bt.table_id = st.table_id where bt.trigger is not null and bt.created_on > TO_TIMESTAMP('$current_time') order by st.name;" | $BENDSQL_CLIENT_CONNECT
## Create table
echo "create table target2(i int);" | $BENDSQL_CLIENT_CONNECT
echo "call  system\$execute_background_job('test_tenant-compactor-job');"
echo "call  system\$execute_background_job('test_tenant-compactor-job');" | $BENDSQL_CLIENT_CONNECT
sleep 5
echo "select st.name bt,type, bt.trigger from system.background_tasks AS bt JOIN system.tables st ON bt.table_id = st.table_id where bt.trigger is not null and bt.created_on > TO_TIMESTAMP('$current_time') order by st.name;" | $BENDSQL_CLIENT_CONNECT
echo "select * from system.processes where type != 'HTTPQuery';" | $BENDSQL_CLIENT_CONNECT

table_ids=$(curl -X GET -s http://localhost:8080/v1/background/test_tenant/background_tasks?timestamp=$encoded_time | jq '[.task_infos[] | .[1].compaction_task_stats.table_id]')

# Convert the table_ids JSON array to a comma-separated list
table_ids_list=$(echo $table_ids | jq -r 'join(",")')

sql="select database, name from system.tables where table_id in ($table_ids_list) order by name;"
echo "$sql" | $BENDSQL_CLIENT_CONNECT

## Drop table
echo "drop table if exists target1;" | $BENDSQL_CLIENT_CONNECT
echo "drop table if exists target2;" | $BENDSQL_CLIENT_CONNECT
