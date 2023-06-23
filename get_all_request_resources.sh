#!/bin/bash
echo "Processing..."
nodes=$(kubectl get pods -o=jsonpath='{.items[*]..spec.nodeName}' -A)
echo "$nodes" | tr ' ' '\n' | sort | uniq > tmp.txt
IFS=$'\r\n' GLOBIGNORE='*' command eval 'nodeArray=($(cat tmp.txt))'
rm -f tmp.txt

declare -A map
declare -A mapCPU

for node in ${nodeArray[@]}
do
   map[$node]=0
   res=$(kubectl get pods -o=jsonpath='{.items[*]..spec.containers[*]..resources.requests.memory}' -A --field-selector spec.nodeName=$node,status.phase=Running)
   total=$(echo $res | tr ' ' '\n' | wc -l)
   counter=0
   for i in $res
   do
      counter=$((counter+1))
      progress=$((counter*100/total))
      if [[ $i =~ "Mi" ]]; then
         i=$(echo $i | sed 's/[^0-9]*//g')	
      else
         i=$(echo $i | sed 's/[^0-9]*//g')
         i=$((i*1024))
      fi
      map[$node]=$((map[$node]+$i))
      echo -ne "\rStart calculating Request Memory for node: $node - $progress%"
   done
   echo ""
done

for node in ${nodeArray[@]}
do
   mapCPU[$node]=0
   resCPU=$(kubectl get pods -o=jsonpath='{.items[*]..spec.containers[*]..resources.requests.cpu}' -A --field-selector spec.nodeName=$node,status.phase=Running)
   total=$(echo $resCPU | tr ' ' '\n' | wc -l)
   counter=0
   for i in $resCPU
   do
      counter=$((counter+1))
      progress=$((counter*100/total))
      if [[ $i =~ "m" ]]; then
         i=$(echo $i | sed 's/[^0-9]*//g')	
      else
         i=$((i*1000))
      fi
      mapCPU[$node]=$((mapCPU[$node]+$i))
      echo -ne "\rStart calculating Request CPU for node: $node - $progress%"
   done
   echo ""
done

totalNodes=${#nodeArray[@]}
counter=0
echo "Node Name,Memory (GiB),CPU" > tmp.result
for node in ${nodeArray[@]}
do
   requestMem=$(echo ${map[$node]}/1024 | node -p)
   requestCPU=$(echo ${mapCPU[$node]}/1000 | node -p)
   counter=$((counter+1))
   progress=$((counter*100/totalNodes))
   sleep 1
   echo -ne "\rGenerating result: $progress%"
   echo "$node,$requestMem,$requestCPU" >> tmp.result
done
echo ""
echo "===================================================="
echo "======================Result========================"
echo "===================================================="
cat result.csv | column -t -s' '
