#!/bin/bash
echo "Script started"

seconds2time ()
{
   T=$1
   D=$((T/60/60/24))
   H=$((T/60/60%24))
   M=$((T/60%60))
   S=$((T%60))

   if [[ ${D} != 0 ]]
   then
      printf '%d days %02d:%02d:%02d' $D $H $M $S
   else
      printf '%02d:%02d:%02d' $H $M $S
   fi
}

mkdir aut
cd aut
TEST_SET="policies_happy_paths.txt"
if [ "$POLICY" == "BASE" ]; then
	wget http://172.30.23.4:8081/artifactory/OpenSDL/${SDL_BUILD}/OpenSDL.tar.gz
else
	wget http://172.30.23.4:8081/artifactory/OpenSDL_${POLICY}_Nightly/${SDL_BUILD}/OpenSDL.tar.gz
fi
if [ "$POLICY" == "HTTP" ]; then
	TEST_SET="policies_happy_paths_HTTP.txt"
fi
if [ "$POLICY" == "EXTENDED" ]; then
	TEST_SET="policies_happy_paths_EXTERNAL_PROPRIETARY.txt"
fi
if [ "$POLICY" == "PROPRIETARY" ]; then
	TEST_SET="policies_happy_paths_PROPRIETARY.txt"
fi

tar -xvf OpenSDL.tar.gz
cd bin
pwd
export LD_LIBRARY_PATH=.
sudo ldconfig
cd ../..
ls -l
git clone https://github.com/smartdevicelink/sdl_atf_test_scripts.git
cd sdl_atf_test_scripts
git checkout feature/external_proprietary_policy
cd ..
ls -l
cp -r ${WORKSPACE}/sdl_atf_test_scripts/. ${WORKSPACE}/
pwd
cp -rf ${WORKSPACE}/aut/bin/api/. ${WORKSPACE}/data/
ls -l data/
echo ${POLICY}

#mkdir tmp

#cp ./test_scripts/Polices/Policies_Security/002_ATF_P_Policies_Performance_Requirement.lua tmp/002_ATF_P_Policies_Performance_Requirement.lua
#cp ./test_scripts/Polices/build_options/ATF_PM_change_status_UPDATE_NEEDED_after_timeout_expired.lua tmp/ATF_PM_change_status_UPDATE_NEEDED_after_timeout_expired.lua
#cp ./test_scripts/Polices/build_options/011_ATF_P_TC_PTS_Define_URL_to_send_PTS_HTTP.lua tmp/011_ATF_P_TC_PTS_Define_URL_to_send_PTS_HTTP.lua

echo "Backup SDL"
#Backup
./SDL_environment_setup.sh -b ${WORKSPACE}/aut/bin
ls -l ${TMPDIR-/tmp}/sdL_backup

echo "<html><head><title>Report</title></head><table border='1'>" >> atf_report.html
echo "<h3><a href='${BUILD_URL}'>${JOB_NAME}</a></h3><br>" >> atf_report.html
echo "Detailed regression report - <a href='${BUILD_URL}/testReport/(root)/lua/'>Tests Run Details</a><br>" >> atf_report.html
echo "<tr><td>Test name</td><td>Test Result</td><td>Execution time.</td></tr>" >> atf_report.html
echo "<testsuites>" >> junit.xml
total_time=0;
pased_tests=0;
failed_tests=0;
echo "<testsuite name='ALL TESTS_${POLICY}'>" >> junit.xml
#for i in $(find ./tmp/ -type f -name "*.lua");
for i in $(cat ./test_sets/${TEST_SET});
do
 if [[ $i != ";"* ]]; then
 echo $i;
 start=$SECONDS;
 ps -aux | grep smartDeviceLinkCore | awk '{print $2}' | xargs kill -9;
 ./start.sh --sdl-core=aut/bin $i | tee console.log ; result=${PIPESTATUS[0]};
 if [ $result -eq 0 ]; then
  	stop=$SECONDS;
 	(( runtime=stop-start ));
 	(( total_time=total_time+runtime ));
	(( pased_tests=pased_tests+1 ))
 	echo "Test passed";
    echo "<tr> <td>$i</td><td bgcolor='green'>Passed</td><td>$runtime</td></tr>" >> atf_report.html;
    echo "<testcase name='$(basename $i .lua)' classname='lua' time='$runtime' />" >> junit.xml;
 fi
 if [ $result -ne 0 ]; then
 	stop=$SECONDS;
 	(( runtime=stop-start ));
 	(( total_time=total_time+runtime ));
	(( failed_tests=failed_tests+1 ))
 	echo "<tr> <td>$i</td><td bgcolor='red'>Failed</td><td>$runtime</td></tr>" >> atf_report.html;
    echo "<testcase name='$(basename $i .lua)' classname='lua' time='$runtime'>" >> junit.xml;
   	echo "<failure message='Something goes wrong'>Test exited with exit code = $result</failure>" >> junit.xml;
    echo "</testcase>" >> junit.xml
    echo "Test failed with exit code = $result!";
	echo "$(basename $i .lua)" >> failed_tests.txt;
    failed=1;
 fi
 echo "Test finished!";

 cp ErrorLog.txt ErrorLog-$(basename $i .lua).txt
 cp aut/bin/SmartDeviceLinkCore.log ${WORKSPACE}/SDL_Log_$(basename $i .lua).txt
 rm -rf aut/bin/smartDeviceLinkCore.log
 ps -aux | grep smartDeviceLinkCore | awk '{print $2}' | xargs kill -9;
 echo "Clean SDL"
 #Clean
 ./SDL_environment_setup.sh -c ${WORKSPACE}/aut/bin
 echo "Restore SDL"
 #Restore
 ./SDL_environment_setup.sh -r ${WORKSPACE}/aut/bin
 else
  echo "Test skipped - $i"
  echo "<tr> <td>$test_script</td><td bgcolor='yellow'>Skipped</td><td>$runtime</td><td><a href='https://adc.luxoft.com/jira/browse/$(echo $i | awk '{print $2}')'>$(echo $i | awk '{print $2}')</a></td></tr>" >> atf_report.html;
  echo "<testcase name='$(basename $test_script .lua)' classname='lua' time='$runtime'>" >> junit.xml;
  echo "<skipped /></testcase>" >> junit.xml
  echo "Test failed with exit code = $result!";
  echo "$(basename $test_script .lua)" >> skipped_tests.txt;  
fi
done
echo "<tr><td></td><td></td><td>Total time: $(seconds2time $total_time)</td></tr>" >> atf_report.html
echo "</table></br>Passed=${pased_tests}, Failed=${failed_tests}</html>" >> atf_report.html
echo "</testsuite>" >> junit.xml
echo "</testsuites>" >> junit.xml

tar -zcvf SDL_Logs.tar.gz ${WORKSPACE}/SDL_Log_*.txt
tar -zcvf TestingReports.tar.gz TestingReports/
tar -zcvf ErrorLogs.tar.gz ErrorLog-*.txt

echo "Script ended"
echo "{ATF_PASSED:${pased_tests} }"
echo "{ATF_FAILED:${failed_tests} }"
echo "{ATF_TOTAL:$(( pased_tests+failed_tests )) }"

wget -O old_failed_tests.txt ${JOB_URL}lastCompletedBuild/artifact/failed_tests.txt

awk '{if (f==1) { r[$0] } else if (! ($0 in r)) { print $0 } } ' f=1 old_failed_tests.txt f=2 failed_tests.txt >> new_failures.txt

NUMOFLINES=$(cat new_failures.txt | wc -l )

cp new_failures.txt new_failures($NUMOFLINES).txt

if [ $failed -ne 0 ]; then
  if [ ${PULL_ID} -ne 0 ]; then
	curl -H "Content-type: application/json" -X POST -u JenkinsSDLOnCloud:1qaz@WSX -d "{\"body\": \"ATF failed(Passed=${pased_tests}, Failed=${failed_tests}) ${BUILD_URL}\", \"in_reply_to\": 0}" https://api.github.comepos/smartdevicelink/sdl_core/issues/${PULL_ID}/comments
  fi
 exit 1
fi