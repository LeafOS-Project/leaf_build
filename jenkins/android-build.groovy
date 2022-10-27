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
                sh "$WORKSPACE/jenkins/build/jenkins/android-build.sh sync"
            }
        }
        stage('Build target-files-package') {
            steps {
                script {
                    env.KEY_DIR="/var/lib/jenkins/.android-certs"
                    env.AVB_ALGORITHM="SHA256_RSA4096"
                    
                    env.LEAF_BUILDTYPE="OFFICIAL"
                    env.BOARD_EXT4_SHARE_DUP_BLOCKS=true
                    env.TARGET_RO_FILE_SYSTEM_TYPE="erofs"
                    env.OVERRIDE_TARGET_FLATTEN_APEX=true
                    
                    if (params.JENKINS_RELEASETYPE == "Alpha") {
                        env.RELEASE_DIR="alpha/"
                    } else if (params.JENKINS_RELEASETYPE == "Beta") {
                        env.RELEASE_DIR="beta/"
                    }
                }
                sh "$WORKSPACE/jenkins/build/jenkins/android-build.sh target-files-package"
            }
        }
        stage('Sign') {
            steps {
                sh "$WORKSPACE/jenkins/build/jenkins/android-build.sh sign"
            }
        }
        stage('Build ota-package') {
            steps {
                sh "$WORKSPACE/jenkins/build/jenkins/android-build.sh ota-package"
            }
        }
        stage('Upload build') {
            steps {
                sh "$WORKSPACE/jenkins/build/jenkins/android-build.sh upload"
            }
        }
    }
    post {
        always {
            sh "$WORKSPACE/jenkins/build/jenkins/android-build.sh cleanup"
        }
    }
}

