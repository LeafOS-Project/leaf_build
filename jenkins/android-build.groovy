#!/usr/bin/env groovy

pipeline {
    agent any
    parameters {
        string(name: 'JENKINS_TARGET', defaultValue: 'lineage_beyond1lte-user', description: '')
        string(name: 'JENKINS_DEVICE', defaultValue: 'beyond1lte', description: '')
        choice(name: 'JENKINS_RELEASETYPE', choices: ['Alpha', 'Beta', 'Release'], description: '')
    }
    options {
       checkoutToSubdirectory('jenkins/build')
       disableConcurrentBuilds()
    }
    stages {
        stage('Sync') {
            steps {
                script {
                    currentBuild.displayName = "${currentBuild.displayName} (${params.JENKINS_DEVICE})"
                }
                android_build("sync")
            }
        }
        stage('Build target-files-package') {
            steps {
                android_build("target-files")
            }
        }
        stage('Sign') {
            steps {
                android_build("sign")
            }
        }
        stage('Build ota-package') {
            steps {
                android_build("ota-files")
            }
        }
        stage('Upload build') {
            steps {
                android_build("upload")
            }
        }
    }
    post {
        always {
            android_build("cleanup")
        }
    }
}

def android_build(String function) {
    sh '''#!/bin/bash
    source $WORKSPACE/script.sh
    '''+function+'''
    '''
}
