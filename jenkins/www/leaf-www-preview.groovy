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
                sh '''#!/bin/bash
                       git init
                       git remote add origin ssh://LeafOS-Jenkins@review.leafos.org:29418/LeafOS-Project/leaf_www
                '''
            }
        }
        stage('Pick commit'){
            steps {
                sh '''#!/bin/bash
                        git fetch origin ${GERRIT_REFSPEC}
                        git checkout FETCH_HEAD
                '''
            }
        }
        stage('Go'){
            steps {
                sh '''#!/bin/bash
                        set -e
			mkdir -p build

                        export MASTER_IP="$(echo $SSH_CLIENT | cut -f1 -d ' ')"
                        export MYSQL_PWD="leaf"
                        echo "CREATE DATABASE leaf_ota; GRANT ALL ON leaf_ota.* TO 'leaf'@'localhost' IDENTIFIED BY 'leaf'; USE leaf_ota;" > build/leaf_ota.sql
                        mariadb-dump -h $MASTER_IP -u leaf leaf_ota >> build/leaf_ota.sql
                        echo "${GERRIT_CHANGE_NUMBER}" > build/gerrit_change.txt

                        docker build -t leafos/leaf_www .
                        docker run --rm -t -v $(pwd):/src leafos/leaf_www
                        if [ $? == 0 ]; then
                                ssh -p 29418 LeafOS-Jenkins@review.leafos.org gerrit review -n OWNER --tag Jenkins --label Verified=+1 -m \\'"PASS: Jenkins : ${BUILD_URL}console\nBuild successful for change $GERRIT_CHANGE_NUMBER, patchset $GERRIT_PATCHSET_NUMBER.\nPreview available at https://www-preview.leafos.org/${GERRIT_CHANGE_NUMBER}"\\' $GERRIT_CHANGE_NUMBER,$GERRIT_PATCHSET_NUMBER
                        else
                                ssh -p 29418 LeafOS-Jenkins@review.leafos.org gerrit review -n OWNER --tag Jenkins --label Verified=-1 -m \\'"FAIL: Jenkins : ${BUILD_URL}console\nBuild failed for change $GERRIT_CHANGE_NUMBER, patchset $GERRIT_PATCHSET_NUMBER"\\' $GERRIT_CHANGE_NUMBER,$GERRIT_PATCHSET_NUMBER
                        fi
                        mkdir -p /var/www/www-preview.leafos.org/${GERRIT_CHANGE_NUMBER}
                        rsync -rh build/static/ jenkins@$MASTER_IP:/var/www/www-preview.leafos.org/${GERRIT_CHANGE_NUMBER} --delete
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
