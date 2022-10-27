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
                leaf_build("sync")
            }
        }
        stage('Build target-files-package') {
            steps {
                leaf_build("target-files")
            }
        }
        stage('Sign') {
            steps {
                leaf_build("sign")
            }
        }
        stage('Build ota-package') {
            steps {
                leaf_build("ota-package")
            }
        }
        stage('Upload build') {
            steps {
                leaf_build("upload")
            }
        }
    }
    post {
        always {
            script {
                env.BUILD_STATUS = "${currentBuild.currentResult}"
            }
            leaf_build("cleanup")
        }
    }
}

def leaf_build(String stage) {
    sh '''#!/bin/bash
    source "$WORKSPACE/jenkins/build/jenkins/leaf-build.sh"
    '''+stage+'''
    '''
}
