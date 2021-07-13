#!/bin/bash

# Experiment 2 Slow CPU

# Server specific configs
##########################
s1="10.3.1.4"
s2="10.3.1.5"
s3="10.3.1.6"

s1name="Dragonboat-vm1"
s2name="Dragonboat-vm2"
s3name="Dragonboat-vm3"

readOperations=50000
writeOperations=50000
keyValueSize=16

username="alexfan"
###########################


# Start servers (Dockers locally, azure servers remotely)
az vm start --resource-group Depfast-test --subscription "Azure Subscription 1" --name "$s1name"
az vm start --resource-group Depfast-test --subscription "Azure Subscription 1" --name "$s2name"
az vm start --resource-group Depfast-test --subscription "Azure Subscription 1" --name "$s3name"

# Node cleanups
ssh -i ~/.ssh/id_rsa $username@"$s1" "sudo rm -rf ~/Dragonboat-Experiment"
ssh -i ~/.ssh/id_rsa $username@"$s1" "sudo cgdelete cpu:db cpu:cpulow cpu:cpuhigh blkio:db memory:db ; true"
ssh -i ~/.ssh/id_rsa $username@"$s1" "sudo /sbin/tc qdisc del dev eth0 root ; true"
sleep 5
ssh -i ~/.ssh/id_rsa $username@"$s2" "sudo rm -rf ~/Dragonboat-Experiment"
ssh -i ~/.ssh/id_rsa $username@"$s2" "sudo cgdelete cpu:db cpu:cpulow cpu:cpuhigh blkio:db memory:db ; true"
ssh -i ~/.ssh/id_rsa $username@"$s2" "sudo /sbin/tc qdisc del dev eth0 root ; true"
sleep 5
ssh -i ~/.ssh/id_rsa $username@"$s3" "sudo rm -rf ~/Dragonboat-Experiment"
ssh -i ~/.ssh/id_rsa $username@"$s3" "sudo cgdelete cpu:db cpu:cpulow cpu:cpuhigh blkio:db memory:db ; true"
ssh -i ~/.ssh/id_rsa $username@"$s3" "sudo /sbin/tc qdisc del dev eth0 root ; true"
sleep 5

# Run dragonboat with my newly written Go file
ssh -i ~/.ssh/id_rsa $username@"$s1" "sudo apt update && sudo apt install git wget gcc g++ cgroup-tools -y && sudo wget https://golang.org/dl/go1.16.5.linux-amd64.tar.gz && sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.16.5.linux-amd64.tar.gz && sudo git clone https://github.com/CodeTiger927/Dragonboat-Experiment.git && cd Dragonboat-Experiment && sudo /usr/local/go/bin/go build -o main . && sudo nohup ./main -nodeid 1 -addr1 $s1:63001 -addr2 $s2:63002 -addr3 $s3:63003"
ssh -i ~/.ssh/id_rsa $username@"$s2" "sudo apt update && sudo apt install git wget gcc g++ cgroup-tools -y && sudo wget https://golang.org/dl/go1.16.5.linux-amd64.tar.gz && sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.16.5.linux-amd64.tar.gz && sudo git clone https://github.com/CodeTiger927/Dragonboat-Experiment.git && cd Dragonboat-Experiment && sudo /usr/local/go/bin/go build -o main . && sudo nohup ./main -nodeid 2 -addr1 $s1:63001 -addr2 $s2:63002 -addr3 $s3:63003"
ssh -i ~/.ssh/id_rsa $username@"$s3" "sudo apt update && sudo apt install git wget gcc g++ cgroup-tools -y && sudo wget https://golang.org/dl/go1.16.5.linux-amd64.tar.gz && sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.16.5.linux-amd64.tar.gz && sudo git clone https://github.com/CodeTiger927/Dragonboat-Experiment.git && cd Dragonboat-Experiment && sudo /usr/local/go/bin/go build -o main . && sudo nohup ./main -nodeid 3 -addr1 $s1:63001 -addr2 $s2:63002 -addr3 $s3:63003"

sleep 10

# Inject slowness into follower, limit server 2's CPU
slowpid=$(ssh -i ~/.ssh/id_rsa "$s2" "sh -c 'pgrep main'")
ssh -i ~/.ssh/id_rsa $username@"$s2" "sudo sh -c 'sudo mkdir /sys/fs/cgroup/cpu/db'"
ssh -i ~/.ssh/id_rsa $username@"$s2" "sudo sh -c 'sudo echo 50000 > /sys/fs/cgroup/cpu/db/cpu.cfs_quota_us'"
ssh -i ~/.ssh/id_rsa $username@"$s2" "sudo sh -c 'sudo echo 1000000 > /sys/fs/cgroup/cpu/db/cpu.cfs_period_us'"
ssh -i ~/.ssh/id_rsa $username@"$s2" "sudo sh -c 'sudo echo $slowpid > /sys/fs/cgroup/cpu/db/cgroup.procs'"

sleep 20


# Run dragonboat on all of them

# Start experiment
go build -o run_experiment run_experiment.go
./run_experiment -write $readoperations -read $writeoperations -keyValueSize $keyValueSize -leaderAddr "$s1":8001>log.txt
# Stop servers
az vm deallocate --resource-group Depfast-test --subscription "Azure Subscription 1" --name "$s1name"
az vm deallocate --resource-group Depfast-test --subscription "Azure Subscription 1" --name "$s2name"
az vm deallocate --resource-group Depfast-test --subscription "Azure Subscription 1" --name "$s3name"