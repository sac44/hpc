#!/bin/sh

datestamp=$(date +'%F')_$RANDOM
logfile=slurm_jobSize_$datestamp.log
tmpfile=slurm_jobSize_$datestamp.tmp

thisyear=$(date +'%Y')

cluster=$(hostname -s | cut -c 1-3)
case $cluster in
   bc4)
        fromyear=2017
        ;;
   pb1)
        fromyear=2021
        ;;
   *)
        echo "cluster \"${cluster}\" not recognised"
        exit 1
        ;;
esac


for YEAR in $(seq $fromyear $thisyear)
do

echo $YEAR

seq -w 1 12 | xargs -n 1 -I{MM} sh -c "sacct -a -X --array --starttime=$YEAR-{MM}-01 --endtime=$YEAR-{MM}-31 --format=JobID,user,group,Account,Partition,NNodes,NCPUS,CPUTimeRAW,AllocTRES,Submit,Start,End -n -P" >> $logfile

#| sed 's/,/|/g' | sed 's/\([0-9]\)T\([0-9]\)/\1 \2/g'" | sed 's/cpu=\([0-9]\+\)|\(mem=\)/cpu=\1|gres\/gpu=0|\2/g'  >> $logfile

#sed 's/cpu=\([0-9]\+\)|\(mem=\)/cpu=\1|gres\/gpu=0|\2/g' | sed -e 's/billing=\([0-9]\+\)|/\1|/g' -e 's/cpu=\([0-9]\+\)|/\1|/g' -e 's/gres\/gpu=\([0-9]\+\)|/\1|/g' -e 's/node=\([0-9]\+\)|/\1|/g'

done

## removing duplicates from concurrent months
cat $logfile | sort -n | uniq > $tmpfile
mv -i -f $tmpfile $logfile

## correcting Dates, removing the central T
sed -i $logfile -e 's/\([0-9]\)T\([0-9]\)/\1 \2/g'


## parsing
# Adding in additional sep for missing TRES
sed -i $logfile -e 's/||/|||||||/g'

# Adding in GRES/GPU for missing GRES/GPU
sed -i $logfile -e 's/cpu=\([0-9]\+\),\(mem=\)/cpu=\1,gres\/gpu=0,\2/g'


## correcting TRES
# adding in field for node if missing from TRES
sed -i $logfile -e 's/\(mem=[0-9]\+[A-Z]\)|\([0-9]\)/\1,node=1|\2/g'

# removing TRES fields 
sed -i $logfile -e 's/billing=\([0-9]\+\),/\1|/g' -e 's/cpu=\([0-9]\+\),/\1|/g' -e 's/gres\/gpu=\([0-9]\+\),/\1|/g' -e 's/node=\([0-9]\+\)|/\1|/g'

sed -i $logfile -e 's/|mem=\([0-9]\+\.[0-9]\+\)\([A-Z]\),/|\1|\2B|/g' -e 's/|mem=\([0-9]\+\)\([A-Z]\),/|\1|\2B|/g'

awk -F'|' '{OFS="|"; if ($13 == "GB") {$12 = $12 * 1024 ; $13 = "MB"}  print $0}' $logfile > $tmpfile
mv -if $tmpfile $logfile

# TRES - correcting for just billing&cpu fields
sed -i $logfile -e 's/|cpu=\([0-9]\+\)|/|\1|||||/g'
