#!groovy

    boolean buildImages = false
    boolean clearImages = true
    boolean cleanAks = false
    def branch = env.GIT_BRANCH?.trim().split('/').last().toLowerCase()

node {

    properties([disableConcurrentBuilds()])

    try {

        env.BUILD_VERSION = "v1"
        env.BUILD_LABEL = 'allthenews'
        buildImages = params.BUILD_IMAGES
        clearImages = params.CLEAR_IMAGES
        cleanAks = params.CLEAN_AKS

        // Check if the build label is set
        if (buildImages) {
            if (!env.BUILD_LABEL) {
                error("Build label must be specified!: build label: ${env.BUILD_LABEL}")
            }
        }

        echo """Parameters:
            branch: '${branch}' 
            BUILD LABEL: '$env.BUILD_LABEL'
            BUILD VERSION: '$env.BUILD_VERSION'
            buildImages: '${buildImages}'
            clearImages: '${clearImages}'
            cleanAks: '${cleanAks}'
        """

        if(cleanAks) {
            // Navigate to fe-service deployment directory
            dir('manifest'){
                // Delete deployments
                sh "kubectl get deployments -n default --no-headers=true | awk '/${env.BUILD_LABEL}/{print \$1}' | xargs kubectl delete -n default deployment"
                sh "kubectl get services -n default --no-headers=true | awk '/${env.BUILD_LABEL}/{print \$1}' | xargs kubectl delete -n default service"
            }
        }
        
        stage("Pull Source") {
            //trying to get the hash without checkout gets the hash set in previous build.
                def checkout = checkout scm
                env.COMMIT_HASH = checkout.GIT_COMMIT
                echo "Checkout done; Hash: '${env.COMMIT_HASH}'"
        }

        def loginGCDocker = {
            sh "sudo usermod -a -G docker ${USER}"
            sh "gcloud auth activate-service-account eadesignserviceprincipal@mscdevopscaauto.iam.gserviceaccount.com --key-file=mscdevopscaauto-827d6ac9e9d5.json"
            sh "gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://eu.gcr.io"
            sh "docker login -u oauth2accesstoken -p \"\$(gcloud auth print-access-token)\" https://eu.gcr.io"
        }

        def buildDockerImage = { imageName ->

            echo "setting version: BUILD_LABEL='${imageName}'; COMMIT_HASH='${env.COMMIT_HASH}'"
            sh "docker build -t '${imageName}:${env.BUILD_VERSION}' ."
            echo "Docker containers built with tag '${imageName}:${env.BUILD_VERSION}'"
            sh "docker images ${imageName}:${env.BUILD_VERSION}"

        }

        def pushDockerImage = { imageName ->
            loginGCDocker()
            sh "chmod +x ${WORKSPACE}/push_images.sh"
            sh "${WORKSPACE}/push_images.sh ${imageName} ${env.BUILD_VERSION}"
            echo "Docker images pushed to repository"
        }

        if(!cleanAks){
            if (buildImages) {
                stage("Build SYNC Images") {
                    dir('sync/allthenews_v2'){
                        buildDockerImage('allthenews2')
                    }
                    dir('sync/allthenews_v3'){
                        buildDockerImage('allthenews3')
                    }
                }
                
                stage("Push Images") {
                    pushDockerImage('allthenews2')
                    pushDockerImage('allthenews3')
                }

                // stage("Build ASYNC Images") {
                //     dir('async/allthenews_v2'){
                //         buildDockerImage('allthenews2')
                //     }
                //     dir('sync/allthenews_v3'){
                //         buildDockerImage('allthenews3')
                //     }
                // }
            }
        }

        stage('Deploy images to GC K8s'){
            dir('sync/manifest'){
                // Create deployments
                ///sh "kubectl create deployment_nf.yaml"
                //sh "kubectl create deployment_wf.yaml"
                sh "kubectl create deployment_atn2.yaml"
                sh "kubectl create deployment_atn3.yaml"
                // Create services
                sh "kubectl create service_atn.yaml"
                //sh "kubectl create service_nf.yaml"
                //sh "kubectl create service_wf.yaml"
            }

        }

    } catch (e) {
        throw e
    } finally {
        if (buildImages && clearImages) {
            stage("Clear Images") {
                echo "Removing images with tag '${env.BUILD_LABEL}'"
                sh "docker images ${env.BUILD_LABEL}"
                sh "docker rmi -f \$(docker images | grep '${env.BUILD_LABEL}' | awk '{print \$3}')"
            }
        }
        // Recursively delete the current directory from the workspace
        deleteDir()
        echo "Build done."
    }
}
