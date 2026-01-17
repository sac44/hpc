CLUSTER=isca

sinfo --all --Node --format="CLUSTER|%P|%t|%E|%N|%c|%m|%G" | sed -e 's/(null)//g' -e 's/\*//g' | \
  sed -e '2,$ s/^CLUSTER/'$CLUSTER'/' | sed 's/GRES/GRES|GRES_MODEL|GRES_COUNT/g' | \
  awk -F'|' '{if ($8 != "") {gsub(":","|",$8); OFS="|" ; print $0} else {print $0"||"}}' \
  > slurm_partitions.psv 
