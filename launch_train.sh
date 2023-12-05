#!/bin/bash

# Check if the runid is provided as a command line argument
if [ $# -lt 4 ]; then
  echo "Usage: $0 <runid> <filename> <num_node> <gpu_per_node>"
  exit 1
fi

runid=$1
filename="./logs/$2.txt"
max_attempts=10
NUM_NODES=$3
NUM_GPU_PER_NODE=$4

# Function to get the IP address and write it to a file
get_and_write_ip() {
  ip_address=$(hostname -I | awk '{print $1}')

  if [ -n "$ip_address" ]; then
    echo "$ip_address" > "$filename"
    echo "IP address $ip_address written to $filename"
  else
    echo "Error: Unable to obtain IP address"
    exit 1
  fi
}

# Function to read the IP address from the file
read_ip_from_file() {
  if [ -f "$filename" ]; then
    ip_address=$(cat "$filename")

    if [[ $ip_address =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "IP address read from $filename: $ip_address"
    else
      echo "Error: Invalid IP address in $filename"
#      exit 1
    fi
  else
    echo "Error: File $filename not found"
#    exit 1
  fi
}

# Main logic
if [ "$runid" -eq 0 ]; then
  get_and_write_ip
else
  attempt=0

  while [ $attempt -lt $max_attempts ]; do
    read_ip_from_file

    # If the IP address is not valid, wait for 3 seconds and try again
    if ! [[ $ip_address =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "Attempt $((attempt + 1)): Invalid IP address in $filename. Retrying in 3 seconds..."
      sleep 3
      ((attempt++))
    else
      echo "Valid IP address read from $filename: $ip_address"
      break
    fi
  done

  if [ $attempt -eq $max_attempts ]; then
    echo "Error: Maximum attempts reached. Unable to read a valid IP address from $filename"
    exit 1
  fi
fi

echo "Stating training ..."
echo ""


/home/pghosh/miniconda3/envs/p_VideoGan80GB/bin/python -m torch.distributed.run --nnodes=$NUM_NODES \
--node_rank $runid --nproc_per_node=$NUM_GPU_PER_NODE --rdzv_endpoint="$ip_address:7745" main.py
