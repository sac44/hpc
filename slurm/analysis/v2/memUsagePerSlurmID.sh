#!/bin/sh


sacct -n --array -a --format JobID,AllocCPUS,MaxRSS,MaxVMSize  --noconvert -P --job=1401278 | \
	sed -e 's/\(^[0-9_]\+\)[\.][0-9A-Za-z]\+/\1/g' | \
	awk -v cluster=$cluster -F'|' 'BEGIN {OFS="|"} {rss[$1] = (rss[$1]>($2*$3)) ? rss[$1] : ($2*$3); vmsize[$1] = (vmsize[$1]>($2*$4)) ? vmsize[$1] : ($2*$4); ncpus[$1] = (ncpus[$1]>$2 ? ncpus[$1] : $2)} END {for (sid in rss) print cluster, sid, ncpus[sid], rss[sid], vmsize[sid], cluster"_"sid}' | \ 
	sed -e 's/\(^[0-9]\+\)/\1\|/g' | \
	sed 's/|_/|/g' 
