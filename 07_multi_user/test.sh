#!/bin/bash

set -e

PWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $PWD/../functions.sh

GEN_DATA_SCALE=$1
session_id=$2
EXPLAIN_ANALYZE=$3

if [[ "$GEN_DATA_SCALE" == "" || "$session_id" == "" || "$EXPLAIN_ANALYZE" == "" ]]; then
	echo "Error: you must provide the scale, the session id, and true/false to run explain analyze as parameters."
	echo "Example: ./rollout.sh 3000 2 false"
	echo "This will execute the TPC-DS queries for 3TB of data for session 2 and not run explain analyze."
	exit 1
fi

source_bashrc

step=testing_$session_id

init_log $step

sql_dir=$PWD/$session_id
#going from 1 base to 0 base
tpcds_id=$((session_id-1))
tpcds_query_name="query_""$tpcds_id"".sql"
query_id=1
for p in $(seq 1 99); do
	q=$(printf %02d $query_id)
	template_filename=query$p.tpl
	start_position=""
	end_position=""
	for pos in $(grep -n $template_filename $sql_dir/$tpcds_query_name | awk -F ':' '{print $1}'); do
		if [ "$start_position" == "" ]; then
			start_position=$pos
		else
			end_position=$pos
		fi
	done

	#get the query number (the order of query execution) generated by dsqgen
	file_id=$(sed -n "$start_position","$start_position"p $sql_dir/$tpcds_query_name | awk -F ' ' '{print $4}')
	file_id=$(($file_id+100))
	filename=$file_id.query.$q.sql

	#add explain analyze 
	echo "echo \":EXPLAIN_ANALYZE\" > $sql_dir/$filename"
	echo ":EXPLAIN_ANALYZE" > $sql_dir/$filename

	echo "sed -n \"$start_position\",\"$end_position\"p $sql_dir/$tpcds_query_name >> $sql_dir/$filename"
	sed -n "$start_position","$end_position"p $sql_dir/$tpcds_query_name >> $sql_dir/$filename
	query_id=$(($query_id + 1))
	echo "Completed: $sql_dir/$filename"
done
echo "rm -f $sql_dir/query_*.sql"
rm -f $sql_dir/$tpcds_query_name

echo ""
echo "queries 14, 23, 24, and 39 have 2 queries in each file.  Need to add :EXPLAIN_ANALYZE to second query in these files"
echo ""
arr=("*.query.14.sql" "*.query.23.sql" "*.query.24.sql" "*.query.39.sql")

for z in "${arr[@]}"; do
	echo $z
	myfilename=$sql_dir/$z
	echo "myfilename: $myfilename"
	pos=$(grep -n ";" $myfilename | awk -F ':' '{print $1}' | head -1)
	pos=$(($pos+1))
	echo "pos: $pos"
	sed -i ''$pos'i\'$'\n'':EXPLAIN_ANALYZE'$'\n' $myfilename
done

tuples="0"
for i in $(ls $sql_dir/*.sql); do

	start_log
	id=$i
	schema_name=$session_id
	table_name=$(basename $i | awk -F '.' '{print $3}')

	if [ "$EXPLAIN_ANALYZE" == "false" ]; then
		echo "psql -A -q -t -P pager=off -v EXPLAIN_ANALYZE="" -f $i | wc -l"
		tuples=$(psql -A -q -t -P pager=off -v EXPLAIN_ANALYZE="" -f $i | wc -l; exit ${PIPESTATUS[0]})
		tuples=$(($tuples-1))
	else
		myfilename=$(basename $i)
		mylogfile=$PWD/../log/"$session_id"".""$myfilename"".multi.explain_analyze.log"
		echo "psql -A -q -t -P pager=off -v EXPLAIN_ANALYZE=\"EXPLAIN ANALYZE\" -f $i"
		psql -A -q -t -P pager=off -v EXPLAIN_ANALYZE="EXPLAIN ANALYZE" -f $i > $mylogfile
		tuples="0"
	fi
		
	#remove the extra line that \timing adds
	log $tuples
done

end_step $step
