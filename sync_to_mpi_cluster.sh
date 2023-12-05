#! /bin/bash
dir_to_sync='DistributeTrainStub'
usr=$1
host_machine=$(hostname)
dest_dir=never_eidt_from_cluster_remote_edit_loc
#dest_dir=never_eidt_from_cluster_remote_edit_loc2
while inotifywait -r --exclude '/\.' ../$dir_to_sync/*; do
  if [ "$host_machine" = "brown" ]; then
    rsync --exclude=".*" -av ../$dir_to_sync/ /is/cluster/$usr/repos/$dest_dir/$dir_to_sync &
    sleep 2
    echo "second sync."
    rsync --exclude=".*" -av ../$dir_to_sync/ /is/cluster/$usr/repos/$dest_dir/$dir_to_sync
  elif [ "$host_machine" = "pghosh-Home" ]; then
    rsync --exclude=".*" -av ../$dir_to_sync/ /home/pghosh/mnt/cluster/pghosh/repos/$dest_dir/$dir_to_sync &
    sleep 2
    echo "second sync."
    rsync --exclude=".*" -av ../$dir_to_sync/ /home/pghosh/mnt/cluster/pghosh/repos/$dest_dir/$dir_to_sync
  else
    rsync --exclude=".*" -azhe "ssh -i ~/.ssh/id_rsa" ../$dir_to_sync/ $usr@brown.is.localnet:/is/cluster/$usr/repos/$dest_dir/$dir_to_sync &
    sleep 2
    echo "second sync."
    rsync --exclude=".*" -azhe "ssh -i ~/.ssh/id_rsa" ../$dir_to_sync/ $usr@brown.is.localnet:/is/cluster/$usr/repos/$dest_dir/$dir_to_sync
  fi
done
