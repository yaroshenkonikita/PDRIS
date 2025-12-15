pipeline {
    agent any

    tools {
        jdk 'jdk17'
    }

    environment {
        // Явно устанавливаем переменные окружения
        JAVA_HOME = tool(name: 'jdk17', type: 'hudson.model.JDK')
        PATH = "${JAVA_HOME}/bin:${PATH}"
        NEXUS_URL = "http://nexus:8081"
        NEXUS_REPOSITORY = "pdris"
        NEXUS_CREDENTIALS_ID = "nexus_cred"
        SONAR_URL = "http://sonarqube:9000"
        SONAR_TOKEN_CREDENTIALS_ID = ""
        SONAR_CREDENTIALS_ID = "sonar_admin"
        APP_REPO_URL = "https://github.com/yaroshenkonikita/PDRIS-app.git"
        APP_REPO_BRANCH = "main"
        GIT_CREDENTIALS_ID = ""
        DEPLOY_JOB_NAME = "pdris-deploy"
    }

    stages {
        stage('Environment Check') {
            steps {
                sh """
                    echo "Java version:"
                    java -version
                    echo "Maven version:"
                    mvn -version
                    echo "Current directory:"
                    pwd
                    echo "JAVA_HOME: ${JAVA_HOME}"
                """
            }
        }

        stage('git clone') {
            steps {
                script {
                    def args = [branch: env.APP_REPO_BRANCH, url: env.APP_REPO_URL]
                    if (env.GIT_CREDENTIALS_ID?.trim()) {
                        args.credentialsId = env.GIT_CREDENTIALS_ID
                    }
                    git args
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    try {
                        def commonArgs = "-DskipTests sonar:sonar -Dsonar.projectKey=pdris-app -Dsonar.projectName=pdris-app -Dsonar.host.url=${env.SONAR_URL}"
                        if (env.SONAR_TOKEN_CREDENTIALS_ID?.trim()) {
                            withCredentials([string(credentialsId: env.SONAR_TOKEN_CREDENTIALS_ID, variable: 'SONAR_TOKEN')]) {
                                sh "mvn -B ${commonArgs} -Dsonar.token=$SONAR_TOKEN"
                            }
                        } else if (env.SONAR_CREDENTIALS_ID?.trim()) {
                            withCredentials([usernamePassword(credentialsId: env.SONAR_CREDENTIALS_ID, usernameVariable: 'SONAR_USER', passwordVariable: 'SONAR_PASS')]) {
                                sh "mvn -B ${commonArgs} -Dsonar.login=$SONAR_USER -Dsonar.password=$SONAR_PASS"
                            }
                        } else {
                            sh "mvn -B ${commonArgs}"
                        }
                    } catch (e) {
                        echo "Sonar stage skipped/failed (check plugin + server): ${e}"
                    }
                }
            }
        }

        stage('Run test') {
            steps {
                sh "mvn -B clean test"
            }
        }

        stage('Generate Allure report') {
            steps {
                script {
                    try {
                        allure includeProperties: false, jdk: '', results: [[path: 'target/allure-results']]
                    } catch (e) {
                        echo "Allure stage skipped/failed (check plugin): ${e}"
                    }
                }
            }
        }

        stage('Deploy to Nexus') {
            steps {
                sh "mvn -B -DskipTests package"
                script {
                    def artifactPath = "pdris-app/${env.BUILD_NUMBER}/pdris-app.jar"
                    env.PUBLISHED_ARTIFACT_URL = "${env.NEXUS_URL}/repository/${env.NEXUS_REPOSITORY}/${artifactPath}"
                }
                withCredentials([usernamePassword(credentialsId: env.NEXUS_CREDENTIALS_ID, usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    sh """
                      echo "Uploading to: ${PUBLISHED_ARTIFACT_URL}"
                      curl -f -u "$NEXUS_USER:$NEXUS_PASS" --upload-file target/pdris-app.jar "${PUBLISHED_ARTIFACT_URL}"
                    """
                }
            }
        }

        stage('Run Job') {
            steps {
                script {
                    build job: env.DEPLOY_JOB_NAME, wait: false, parameters: [
                        string(name: 'ARTIFACT_URL', value: env.PUBLISHED_ARTIFACT_URL),
                        string(name: 'NEXUS_CREDENTIALS_ID', value: env.NEXUS_CREDENTIALS_ID)
                    ]
                }
            }
        }
    }
}
