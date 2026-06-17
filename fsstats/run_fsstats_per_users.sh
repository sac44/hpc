dir=/<<location>>/scripts/fsstats/per-user/$(date +%Y-%m-%d)
mkdir -p $dir
log=$dir/fsstats_progress.log
err=$dir/fsstats_progress.err
for d in $(ls -d /beegfs/scratch/user/[a-z]/*)
#        do f=$(echo $d | cut -c2- | tr '/' '-')
        do f=$(echo $d | cut -c2- | tr '/' '_')_$(ls -dn $d | awk '{print $3}')
	echo $d $f >> $log

        ($dir/../../fsstats.pl -o $dir/$f.csv $d > $dir/$f.log) 2> $err

done


