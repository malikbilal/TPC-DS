#!/bin/bash
set -e

PWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $PWD/../functions.sh
source_bashrc

GEN_DATA_SCALE=$1
EXPLAIN_ANALYZE=$2
RANDOM_DISTRIBUTION=$3
MULTI_USER_COUNT=$4
SINGLE_USER_ITERATIONS=$5

if [[ "$GEN_DATA_SCALE" == "" || "$EXPLAIN_ANALYZE" == "" || "$RANDOM_DISTRIBUTION" == "" || "$MULTI_USER_COUNT" == "" || "$SINGLE_USER_ITERATIONS" == "" ]]; then
	echo "You must provide the scale as a parameter in terms of Gigabytes, true/false to run queries with EXPLAIN ANALYZE option, true/false to use random distrbution, multi-user count, and the number of sql iterations."
	echo "Example: ./rollout.sh 100 false tpcds false 5 1"
	exit 1
fi

step="score"
init_log $step

load_time=$(psql -q -t -A -c "select sum(extract('epoch' from duration)) from tpcds_reports.load where tuples > 0")
analyze_time=$(psql -q -t -A -c "select sum(extract('epoch' from duration)) from tpcds_reports.load where tuples = 0")
queries_time=$(psql -q -t -A -c "select min(extract('epoch' from duration)) from tpcds_reports.sql")
concurrent_queries_time=$(psql -q -t -A -c "select sum(extract('epoch' from duration)) from tpcds_testing.sql")

q=$((3*MULTI_USER_COUNT*99))
tpt=$((queries_time*MULTI_USER_COUNT))
tld=$((0.01*MULTI_USER_COUNT*load_time))

num_score=$((GEN_DATA_SCALE*q))
dem_score=$((tpt+2*concurrent_queries_time+tld))

score=$((num_score/dem_score))
score=$(echo $score | awk -F '.' '{print $1}')

echo -e "Scale Factor\t$GEN_DATA_SCALE"
echo -e "Load\t$load_time"
echo -e "Analyze\t$analyze_time"
echo -e "Queries\t$queries_time"
echo -e "5 Users Sum\t$concurrent_queries_time"
echo -e "Q\t$q"
echo -e "TPT\t$tpt"
echo -e "TTT\t$concurrent_queries_time"
echo -e "TLD\t$tld"
echo -e "Score\t$score"

end_step $step
