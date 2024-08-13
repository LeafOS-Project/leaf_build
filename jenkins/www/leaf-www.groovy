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
                        export GERRIT_URL="ssh://LeafOS-Jenkins@review.leafos.org:29418/LeafOS-Project/leaf_www"
                        ssh jenkins@$MASTER_IP git -C /var/www/leafos.org/ reset --hard
                        ssh jenkins@$MASTER_IP git -C /var/www/leafos.org/ pull ${GERRIT_URL} ${GERRIT_REFSPEC}
                        ssh jenkins@$MASTER_IP "cd /var/www/leafos.org; composer install"
                        ssh jenkins@$MASTER_IP chmod -R a+rwx /var/www/leafos.org/var/cache/
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
