#!/usr/bin/env bash 
declare -a time
for file in *.xml
  do 
     tests=$(xmlstarlet  sel -T -t -m "/testsuites/@tests" -v . -n $file)
           for i in "${tests[@]}"
           do
         let "ts += $i"
       done
     failures=$(xmlstarlet  sel -T -t -m "/testsuites/@failures" -v . -n $file)
           for i in "${failures[@]}"
             do
           let "f += $i"
        done
     disabled=$(xmlstarlet  sel -T -t -m "/testsuites/@disabled" -v . -n $file)
           for i in "${disabled[@]}"
             do
           let "d += $i"
        done
     errors=$(xmlstarlet  sel -T -t -m "/testsuites/@errors" -v . -n $file)
           for i in "${errors[@]}"
             do
           let "e += $i"
        done
     time=$(xmlstarlet  sel -T -t -m "/testsuites/@time" -v . -n $file)
         
     for i in $time
        do
      array+=($i)
    done


done

echo ${array[*]}
tm=$( IFS="+"; bc <<< "${array[*]}" ) 
echo tests=$ts
echo disabled=$d
echo failures=$f
echo errors=$e
echo time=$tm
echo  "<td id="summaryTests" align="center">$ts</td>">>temp.txt
echo  "<td id="summaryFailures" align="center">$f</td>">>temp.txt
echo  "<td id="summaryDisabled" align="center">$d</td>">>temp.txt
echo  "<td id="summaryErrors" align="center">$e</td>">>temp.txt
echo  "<td id="summaryTime" align="center">$tm</td>">>temp.txt
sed -i '11r temp.txt' report.html