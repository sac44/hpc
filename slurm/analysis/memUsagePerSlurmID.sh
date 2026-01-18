#!/bin/sh
  
datestamp=$(date +'%F')
logfile=memUsagePerSlurmID/memUsagePerSlurmID_${datestamp}_$RANDOM.log

thisyear=$(date +'%Y')
cluster=$1

echo $cluster

headers="CLUSTER|SLURM_JOB_ID|NTASKS|MAXRSS|REQMEM|MAXVMSIZE|NCPUS|NNODES|MEMPERNODE|ASSOC_ID"

for YEAR in $(seq 2023 $thisyear)
do

  for MM in $(seq -w 01 12)
  do

  logfile=memUsagePerSlurmID/memUsagePerSlurmID_${cluster}_${YEAR}_${MM}.csv
  echo $logfile
  echo $headers > $logfile

  ## $1 JobID, $2 NTasks, $3 MaxRSS, $4 MaxVMSize, $5 REQMEM, $6 AllocCPUS, $7 NNodes

  sacct -n --array -a --format JobID,NTasks,MaxRSS,MaxVMSize,REQMEM,AllocCPUS,NNodes  --noconvert -P --start=$YEAR-$MM-01 --end=$YEAR-$MM-31 | \
        sed -e 's/\(^[0-9_]\+\)[\.][0-9A-Za-z]\+/\1/g' | sed 's/\([0-9]\)M|/\1|/g' | \
        awk -v cluster=$cluster -F'|' 'BEGIN {OFS="|"} {rss[$1] = (rss[$1]>($2*$3)) ? rss[$1] : ($2*$3); vmsize[$1] = (vmsize[$1]>($2*$4)) ? vmsize[$1] : ($2*$4); ntasks[$1] = (ntasks[$1]>$2 ? ntasks[$1] : $2); reqmem[$1] = (reqmem[$1]>($5)) ? reqmem[$1] : ($5); ncpus[$1] = (ncpus[$1]>($6)) ? ncpus[$1] : ($6); nnodes[$1] = (nnodes[$1]>($7)) ? nnodes[$1] : ($7)} END {for (sid in rss) print cluster, sid, ntasks[sid], rss[sid], reqmem[sid]*1024^2, vmsize[sid], ncpus[sid], nnodes[sid], rss[sid] / nnodes[sid], cluster"_"sid}' | sed -e 's/\(^[0-9]\+\)/\1\|/g' | sed 's/|_/|/g' | tee >> $logfile

  done
done

