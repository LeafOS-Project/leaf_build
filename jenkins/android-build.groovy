#!/usr/bin/env groovy

pipeline {
    agent any
    parameters {
        string(name: 'JENKINS_DEVICE', defaultValue: 'beyond1lte', description: '')
        string(name: 'JENKINS_LUNCH', defaultValue: 'lineage', description: '')
        string(name: 'JENKINS_REPOPICK', defaultValue: '', description: '')
        choice(name: 'JENKINS_BUILDTYPE', choices: ['user', 'userdebug', 'eng'], description: '')
        choice(name: 'JENKINS_RELEASETYPE', choices: ['alpha', 'beta', 'release'], description: '')
        booleanParam(name: 'JENKINS_CLEAN', defaultValue: true, description: '')
        booleanParam(name: 'JENKINS_TELEGRAM', defaultValue: true, description: '')
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
                android_build("ota-package")
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

def android_build(String stage) {
    sh '''#!/bin/bash
    source "$WORKSPACE/jenkins/build/jenkins/android-build.sh"
    '''+stage+'''
    '''
}
