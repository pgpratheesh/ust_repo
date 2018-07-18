#!/usr/bin/env groovy

pipeline{
  agent any
  stages{
    stage('Downloading CentOS Latest'){
      steps{
        sh "docker pull centos:latest"
      }
    }
    stage('Creating a Docker container with CentOS'){
      steps{
        sh "docker run centos /bin/bash"
      }
    }
 stage('Running docker ') {   
    steps {
    sh'docker run centos:latest'
}
}
  }
}
