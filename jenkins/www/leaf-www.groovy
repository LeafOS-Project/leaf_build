pipeline {
    agent any
    options {
        checkoutToSubdirectory('jenkins/build')
        disableConcurrentBuilds()
    }
    stages {
        stage('Init'){
            steps {
                cleanWs()
            }
        }
        stage('Push to production'){
            steps {
                sh '''#!/bin/bash
                        set -e

                        export MASTER_IP="$(echo $SSH_CLIENT | cut -f1 -d ' ')"
                        ssh $MASTER_IP git -C /var/www/leafos.org/ git fetch refs/changes/${GERRIT_CHANGE_NUMBER: -2}/${GERRIT_CHANGE_NUMBER}/${GERRIT_PATCHSET_NUMBER}
                        ssh $MASTER_IP git -C /var/www/leafos.org/ git reset --hard FETCH_HEAD
                        ssh $MASTER_IP "cd /var/www/leafos.org; composer install"
                '''
            }
        }
    }
    post {
        always {
            deleteDir()
        }
    }
}
