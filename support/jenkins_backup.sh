#!/bin/bash

sudo rm -rf /home/jenkins/shared_folder_jenkins/backup/*
sudo cp -r /home/jenkins/docker/jenkins_files/ /home/jenkins/shared_folder_jenkins/backup/
cd /home/jenkins/shared_folder_jenkins/backup/
tar -zcvf "jenkins_backup_$(date '+%d-%m-%y').tar.gz" jenkins_files
