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
TEST_SET=${TEST_SET}
wget http://172.30.23.4:8081/artifactory/OpenSDL_Func_PR/${POLICY}/${BUILD_NUMBER}/OpenSDL.tar.gz
tar -xvf OpenSDL.tar.gz
cd bin
pwd
export LD_LIBRARY_PATH=.
sudo ldconfig
cd ../..
git clone https://github.com/smartdevicelink/sdl_atf_test_scripts.git
cd sdl_atf_test_scripts
git checkout ${BRANCH}
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
echo "<html><head><title>ATF Pull Request ${POLICY} Report - Build#${BUILD_NUMBER}</title></head>" >> atf_report.html

echo "<script src='https://code.jquery.com/jquery-3.1.1.min.js' integrity='sha256-hVVnYaiADRTO2PzUGmuLJr8BLUSjGIZsDYGmIJLv2b8=' crossorigin='anonymous'></script>" >> atf_report.html
echo "<script src='https://code.jquery.com/ui/1.12.0/jquery-ui.min.js' integrity='sha256-eGE6blurk5sHj+rmkfsGYeKyZx3M4bG+ZlFyA7Kns7E=' crossorigin='anonymous'></script>" >> atf_report.html
echo "<link href='https://cdn.datatables.net/1.10.13/css/jquery.dataTables.min.css' rel='stylesheet'>" >> atf_report.html
echo "<link href='https://cdn.datatables.net/buttons/1.2.4/css/buttons.dataTables.min.css' rel='stylesheet'>" >> atf_report.html
echo "<link href='https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.0.0-alpha.5/css/bootstrap.css' rel='stylesheet'>" >> atf_report.html
echo "<script src='https://cdn.datatables.net/1.10.13/js/jquery.dataTables.min.js'></script>" >> atf_report.html
echo "<script src='https://cdn.datatables.net/buttons/1.2.4/js/dataTables.buttons.min.js'></script>" >> atf_report.html
echo "<script src='https://cdnjs.cloudflare.com/ajax/libs/jszip/2.5.0/jszip.min.js'></script>" >> atf_report.html
echo "<script src='https://cdn.rawgit.com/bpampuch/pdfmake/0.1.18/build/pdfmake.min.js'></script>" >> atf_report.html
echo "<script src='https://cdn.rawgit.com/bpampuch/pdfmake/0.1.18/build/vfs_fonts.js'></script>" >> atf_report.html
echo "<script src='https://cdn.datatables.net/buttons/1.2.4/js/buttons.html5.min.js'></script>" >> atf_report.html
echo "<script src='https://cdn.datatables.net/1.10.13/js/dataTables.bootstrap4.min.js'></script>" >> atf_report.html


echo "<script> \$(document).ready(function() {\$('#example').DataTable({paging: false, bSortClasses : false, dom: 'Bfrtip', buttons: ['copyHtml5', 'excelHtml5', 'csvHtml5', 'pdfHtml5']});} );</script>" >> atf_report.html

echo "<h3><a href='${BUILD_URL}'>${JOB_NAME}</a></h3><br>" >> atf_report.html
echo "Detailed regression report - <a href='${BUILD_URL}/testReport/(root)/lua/'>Tests Run Details</a><br><br>" >> atf_report.html
echo "<table border='1' id="example" class='table table-striped table-bordered display compact stripe hover' cellspacing="0" width="100%">" >> atf_report.html
echo "<thead><tr><th>Test name</th><th>Test Result</th><th>Execution time.</th><th>Jira Issue</th></tr></thead>" >> atf_report.html
echo "<testsuites>" >> junit.xml
total_time=0;
pased_tests=0;
failed_tests=0;
echo "<testsuite name='ALL TESTS_${POLICY}'>" >> junit.xml
#for i in $(find ./tmp/ -type f -name "*.lua");
echo "$(cat ./test_sets/$TEST_SET)" 
touch failed_tests.txt;
touch success_tests.txt;
failed=0;
while read -r i
do
 test_script=$(echo $i | awk '{print $1}')
 if [[ $i != ";"* ]]; then
 echo "Jira = " $i | awk '{print $2}';
 test_script=$(echo $i | awk '{print $1}')
 echo "Script = "$test_script
 start=$SECONDS;
 ps -aux | grep smartDeviceLinkCore | awk '{print $2}' | xargs kill -9;
 ./start.sh --sdl-core=${WORKSPACE}/aut/bin $test_script | tee console.log ; result=${PIPESTATUS[0]};
 if [ $result -eq 0 ]; then
  	stop=$SECONDS;
 	(( runtime=stop-start ));
 	(( total_time=total_time+runtime ));
	(( pased_tests=pased_tests+1 ))
 	echo "Test passed";
    echo "<tr> <td>$test_script</td><td bgcolor='green'>Passed</td><td>$runtime</td><td><a href='https://adc.luxoft.com/jira/browse/$(echo $i | awk '{print $2}')'>$(echo $i | awk '{print $2}')</a></td></tr>" >> atf_report.html;
    echo "<testcase name='$(basename $test_script .lua)' classname='lua' time='$runtime' />" >> junit.xml;
 fi
 if [ $result -ne 0 ]; then
 	stop=$SECONDS;
 	(( runtime=stop-start ));
 	(( total_time=total_time+runtime ));
	(( failed_tests=failed_tests+1 ))
 	echo "<tr> <td>$test_script</td><td bgcolor='red'>Failed</td><td>$runtime</td><td><a href='https://adc.luxoft.com/jira/browse/$(echo $i | awk '{print $2}')'>$(echo $i | awk '{print $2}')</a></td></tr>" >> atf_report.html;
    echo "<testcase name='$(basename $test_script .lua)' classname='lua' time='$runtime'>" >> junit.xml;
   	echo "<failure message='Something goes wrong'>Test exited with exit code = $result</failure>" >> junit.xml;
    echo "</testcase>" >> junit.xml
    echo "Test failed with exit code = $result!";
	echo "$(basename $test_script .lua)" >> failed_tests.txt;
    failed=1;
 fi
 echo "Test finished!";

 cp ErrorLog.txt ErrorLog-$(basename $test_script .lua).txt
 cp aut/bin/SmartDeviceLinkCore.log ${WORKSPACE}/SDL_Log_$(basename $test_script .lua).txt
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
done < ./test_sets/$TEST_SET
echo "</table><br>Total time: $(seconds2time $total_time)" >> atf_report.html
echo "</br>Passed=${pased_tests}, Failed=${failed_tests}</html>" >> atf_report.html
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



#cp new_failures.txt new_failures($NUMOFLINES).txt

if [ $failed -ne 0 ]; then
  if [ ${PULL_ID} -ne 0 ]; then
	awk '{if (f==1) { r[$0] } else if (! ($0 in r)) { print $0 } } ' f=1 old_failed_tests.txt f=2 failed_tests.txt >> new_failures.txt

	NUMOFLINES=$(cat new_failures.txt | wc -l )
	curl -H "Content-type: application/json" -X POST -u JenkinsSDLOnCloud:1qaz@WSX -d "{\"body\": \"ATF failed(Passed=${pased_tests}, Failed=${failed_tests}) ${BUILD_URL}\", \"in_reply_to\": 0}" https://api.github.comepos/smartdevicelink/sdl_core/issues/${PULL_ID}/comments
  fi
 exit 1
fi