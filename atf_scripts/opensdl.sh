#!/bin/bash
locale
sudo apt-get update
sudo apt-get install -y gdb;
ulimit -c unlimited;

GIT_BRANCH="$(git name-rev --name-only HEAD)"
prefix="origin/"
GIT_BRANCH=$(basename ${GIT_BRANCH})
ghprbPullId="$(git rev-parse HEAD)"

echo "GIT BRANCH="${GIT_BRANCH}

cppcheck --enable=all --inconclusive -i "src/3rd_party-static" -i "src/3rd_party" --xml --xml-version=2 -q src 2> cppcheck.xml

cd build
export THIRD_PARTY_INSTALL_PREFIX=${WORKSPACE}/build/src/3rdparty/LINUX
export THIRD_PARTY_INSTALL_PREFIX_ARCH=${THIRD_PARTY_INSTALL_PREFIX}/x86
export LD_LIBRARY_PATH=$THIRD_PARTY_INSTALL_PREFIX_ARCH/lib
make -j4 install
sudo ldconfig
mkdir /tmp/corefiles
sudo chmod -R 777 /tmp/corefiles
make test | tee ut.log || true; result=${PIPESTATUS[0]};
if [ $result -ne 0 ]; then
 COREFILE=$(find /tmp/corefiles -type f -name "core*");
 echo $COREFILE;
 grep -w "SegFault" ut.log | while read -r line; do 
  arr=($line); 
  echo ${arr[3]};
 done > res.txt;
 test_file=$(find ${WORKSPACE}/build/src/components/ -type f -name $(cat res.txt));
 echo $test_file;
 echo "Started gdb!";
 echo thread apply all bt | gdb $test_file $COREFILE;
 
 #sudo apt-get update

 #sudo apt-get install -y \
 #   apt-transport-https \
 #   ca-certificates \
 #   curl \
 #   software-properties-common
    
 #sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

 #sudo add-apt-repository \
 #  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
 #  $(lsb_release -cs) \
 #  stable"

 #sudo apt-get update

 #sudo apt-get install docker-ce -y --allow-unauthenticated

 #sudo docker -H 172.30.19.219:4550 commit ${DOCKER_CONTAINER_ID} opensdl_rc_off:${BUILD_NUMBER}
 
 exit 1;
fi
ls -l ${LD_LIBRARY_PATH}
ls -l ${THIRD_PARTY_INSTALL_PREFIX_ARCH}
ls -l ${THIRD_PARTY_INSTALL_PREFIX}
echo ${LD_LIBRARY_PATH}
echo ${THIRD_PARTY_INSTALL_PREFIX_ARCH}
echo ${THIRD_PARTY_INSTALL_PREFIX}
cp -r ${WORKSPACE}/build/src/3rdparty/LINUX/x86/lib/. ${WORKSPACE}/build/bin/
mkdir ${WORKSPACE}/build/bin/api
cp -r ${WORKSPACE}/src/components/interfaces/. ${WORKSPACE}/build/bin/api/
tar -zcvf OpenSDL.tar.gz bin/
curl -u admin:1qaz@WSX -X PUT "http://172.30.23.4:8081/artifactory/OpenSDL_sdl_remote_control_baseline/PUSH/${BUILD_NUMBER}/RC/OpenSDL_OFF.tar.gz" -T OpenSDL.tar.gz
