#!groovy

    boolean buildImages = false
    boolean clearImages = true
    boolean cleanAks = false
    boolean pushImages = false
    def branch = env.GIT_BRANCH?.trim().split('/').last().toLowerCase()

node {

    properties([disableConcurrentBuilds()])

    try {

        env.BUILD_VERSION = "v1"
        env.BUILD_LABEL = 'allthenews'
        buildImages = params.BUILD_IMAGES
        clearImages = params.CLEAR_IMAGES
        cleanAks = params.CLEAN_AKS
        pushImages = params.PUSH_IMAGES

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
            pushImages: '${pushImages}'
        """

        if(cleanAks) {
            // Navigate to fe-service deployment directory
            dir('manifest'){
                // Delete deployments
                sh "kubectl get deployments -n default --no-headers=true | awk '/atn/{print \$1}' | xargs kubectl delete -n default deployment" || echo true
                sh "kubectl get deployments -n default --no-headers=true | awk '/door/{print \$1}' | xargs kubectl delete -n default deployment" || echo true
                sh "kubectl get deployments -n default --no-headers=true | awk '/nf/{print \$1}' | xargs kubectl delete -n default deployment" || echo true
                sh "kubectl get deployments -n default --no-headers=true | awk '/redis/{print \$1}' | xargs kubectl delete -n default deployment" || echo true
                sh "kubectl get deployments -n default --no-headers=true | awk '/seccon/{print \$1}' | xargs kubectl delete -n default deployment" || echo true
                sh "kubectl get deployments -n default --no-headers=true | awk '/wf/{print \$1}' | xargs kubectl delete -n default deployment" || echo true
                
                // Delete services
                sh "kubectl get services -n default --no-headers=true | awk '/atn/{print \$1}' | xargs kubectl delete -n default service" || echo true
                sh "kubectl get services -n default --no-headers=true | awk '/nf/{print \$1}' | xargs kubectl delete -n default service" || echo true
                sh "kubectl get services -n default --no-headers=true | awk '/redis/{print \$1}' | xargs kubectl delete -n default service" || echo true
                sh "kubectl get services -n default --no-headers=true | awk '/seccon/{print \$1}' | xargs kubectl delete -n default service" || echo true
                sh "kubectl get services -n default --no-headers=true | awk '/wf/{print \$1}' | xargs kubectl delete -n default service" || echo true
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

        def createFirewallRule = { rulePort ->
            sh "chmod +x ${WORKSPACE}/deployFirewallRules.sh"
            sh "${WORKSPACE}/deployFirewallRules.sh ${rulePort}"
        }

        if(!cleanAks){
            if (buildImages) {
                stage('Build nf and wf services images'){
                    dir('newsfetcher'){
                        buildDockerImage('newsfetcher')
                    }
                    dir('weatherfetcher'){
                        buildDockerImage('weatherfetcher')
                    }
                    if(pushImages){
                        pushDockerImage('newsfetcher')
                        pushDockerImage('weatherfetcher')
                    }
                }
                
                stage("Build SYNC Images") {
                    dir('sync/allthenews_v2'){
                        buildDockerImage('allthenews2')
                    }
                    dir('sync/allthenews_v3'){
                        buildDockerImage('allthenews3')
                    }
                }

                // Push images for the sync applications
                if(pushImages){
                    stage("Push Images") {
                        pushDockerImage('allthenews2')
                        pushDockerImage('allthenews3')
                    }
                }

                stage("Build ASYNC Images") {
                    dir('async/door1'){
                        buildDockerImage('door1')
                    }
                    dir('async/door2'){
                        buildDockerImage('door2')
                    }
                    dir('async/door3'){
                        buildDockerImage('door3')
                    }
                    dir('async/seccon'){
                        buildDockerImage('seccon')
                    }
                }

                // Push images for the async applications
                if(pushImages){
                    stage("Push Images") {
                        pushDockerImage('door1')
                        pushDockerImage('door2')
                        pushDockerImage('door3')
                        pushDockerImage('seccon')
                    }
                }
            }
        }
    

        stage('Deploy images to GC K8s'){
            dir('sync/manifests'){

                // Create sync application deployments and services
                sh "gcloud container clusters get-credentials mscdevopsk8s --zone europe-west1-b --project mscdevopscaauto"
                sh "kubectl apply -f deployment_nf.yaml"
                sh "kubectl apply -f deployment_wf.yaml"
                sh "kubectl apply -f deployment_atn2.yaml"
                sh "kubectl apply -f deployment_atn3.yaml"
                
                // Deploy services
                sh "kubectl apply -f service_nf.yaml"
                sh "kubectl apply -f service_wf.yaml"
                sh "kubectl apply -f service_atn.yaml"

                //Create firewall rules
                createFirewallRule('31916')
            }

            dir('async/manifests'){
                
                // Create async application deployments and services
                sh "kubectl apply -f deployment_d1.yaml"
                sh "kubectl apply -f deployment_d2.yaml"
                sh "kubectl apply -f deployment_d3.yaml"
                sh "kubectl apply -f redis.yaml"
                sh "kubectl apply -f seccon.yaml"
                createFirewallRule('31080')
            }

            // Display all external ips
            sh "kubectl describe nodes | grep ExternalIP"

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
