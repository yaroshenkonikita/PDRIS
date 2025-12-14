pipeline {
    agent any

    parameters {
        string(name: 'ARTIFACT_URL', defaultValue: '', description: 'URL до jar в Nexus')
        string(name: 'NEXUS_CREDENTIALS_ID', defaultValue: 'nexus_cred', description: 'Credentials ID для Nexus')
        string(name: 'DEPLOY_REPO_URL', defaultValue: 'https://github.com/yaroshenkonikita/PDRIS-deploy.git', description: 'Git repo с Ansible')
        string(name: 'DEPLOY_REPO_BRANCH', defaultValue: 'main', description: 'Ветка Ansible repo')
        string(name: 'GIT_CREDENTIALS_ID', defaultValue: '', description: 'Credentials ID для Git (опционально)')
        string(name: 'INVENTORY', defaultValue: 'ansible/inventory/hosts.ini', description: 'Inventory файл')
        string(name: 'PLAYBOOK', defaultValue: 'ansible/playbooks/deploy.yml', description: 'Playbook путь')
    }

    environment {
        // Явно устанавливаем переменные окружения
        NEXUS_URL = "http://nexus:8081"
    }

    stages {
        stage('Download from Nexus') {
            steps {
                script {
                    if (!params.ARTIFACT_URL?.trim()) {
                        error("ARTIFACT_URL is required")
                    }
                }
                withCredentials([usernamePassword(credentialsId: params.NEXUS_CREDENTIALS_ID, usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    sh """
                      rm -f pdris-app.jar
                      echo "Downloading: ${ARTIFACT_URL}"
                      curl -f -u "$NEXUS_USER:$NEXUS_PASS" -o pdris-app.jar "${ARTIFACT_URL}"
                      ls -la pdris-app.jar
                    """
                }
            }
        }

        stage('Git clone ansible') {
            steps {
                script {
                    def args = [branch: params.DEPLOY_REPO_BRANCH, url: params.DEPLOY_REPO_URL]
                    if (params.GIT_CREDENTIALS_ID?.trim()) {
                        args.credentialsId = params.GIT_CREDENTIALS_ID
                    }
                    git args
                }
            }
        }

        stage('Inject inventory for docker app host') {
            steps {
                script {
                    def inventoryPath = params.INVENTORY ?: 'ansible/inventory/hosts.ini'
                    def inventoryContent = '''[app_hosts]
# Dockerized app host (service name: app / container: pdris-app-host)
app ansible_host=app ansible_user=root ansible_password=admin ansible_port=22 ansible_python_interpreter=/usr/bin/python3
'''
                    writeFile file: inventoryPath, text: inventoryContent
                }
            }
        }

        stage('Prepare SSH known_hosts') {
            steps {
                sh '''
                  set -e
                  mkdir -p ~/.ssh
                  ssh-keyscan -p 22 -t rsa app >> ~/.ssh/known_hosts
                '''
            }
        }

        stage('Run ansible') {
            steps {
                sh """
                  set -e
                  export ANSIBLE_CONFIG=ansible/ansible.cfg
                  export ANSIBLE_HOST_KEY_CHECKING=False
                  ansible-playbook -i "${INVENTORY}" "${PLAYBOOK}" \
                    -e artifact_local_path="${WORKSPACE}/pdris-app.jar"
                """
            }
        }
    }
}
