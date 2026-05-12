pipeline {
    agent any

    environment {
        IMAGE_NAME = "sudeepkumarreddyeaga/portfolio-ci-cd"
        IMAGE_TAG = "latest"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                url: 'https://github.com/SudeepReddyEaga/portfolio-ci-cd.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $IMAGE_NAME:$IMAGE_TAG .'
            }
        }

        stage('Push To DockerHub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {

                    sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'

                    sh 'docker push $IMAGE_NAME:$IMAGE_TAG'
                }
            }
        }

        stage('Deploy To Kubernetes') {
            steps {

                sh '''
                KUBECONFIG=/var/jenkins_home/.kube/config \
                kubectl apply -f k8s/deployment.yaml --validate=false
                '''

                sh '''
                KUBECONFIG=/var/jenkins_home/.kube/config \
                kubectl apply -f k8s/service.yaml --validate=false
                '''

                sh '''
                KUBECONFIG=/var/jenkins_home/.kube/config \
                kubectl rollout restart deployment portfolio-deployment
                '''
            }
        }

        stage('Verify Deployment') {
            steps {

                sh '''
                KUBECONFIG=/var/jenkins_home/.kube/config \
                kubectl get pods
                '''

                sh '''
                KUBECONFIG=/var/jenkins_home/.kube/config \
                kubectl get services
                '''
            }
        }
    }

    post {

        success {
            echo 'CI/CD Pipeline Executed Successfully!'
        }

        failure {
            echo 'Pipeline Failed!'
        }
    }
}