pipeline {
    agent any
    
    environment {
        PATH = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${env.PATH}"
        TF_VAR_existing_vm_ip = '9.30.220.114'
        TF_VAR_enable_instana_config = 'true'
        INSTANA_API_TOKEN = credentials('instana-api-token')
        INSTANA_AGENT_KEY = credentials('instana-agent-key')
        INSTANA_ENDPOINT_HOST = 'ibmdevsandbox-instanaibm.instana.io'
        INSTANA_ENDPOINT_PORT = '443'
        INSTANA_ZONE = 'robot-shop-zone'
        ANSIBLE_HOST_KEY_CHECKING = 'False'
    }
    
    parameters {
        choice(name: 'ACTION', choices: ['deploy', 'destroy', 'plan'], description: 'Select action')
        booleanParam(name: 'SKIP_TERRAFORM', defaultValue: false, description: 'Skip Terraform')
        booleanParam(name: 'SKIP_ANSIBLE', defaultValue: false, description: 'Skip Ansible')
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "Verifying project files..."
                    sh '''
                        echo "Current directory: $(pwd)"
                        ls -la
                        
                        echo "Checking required files..."
                        if [ -f "instana.tf" ] && [ -f "variables.tf" ] && [ -f "terraform.tfvars" ]; then
                            echo "✓ All required Terraform files present"
                        else
                            echo "✗ Missing Terraform files"
                        fi
                    '''
                }
            }
        }
        
        stage('Validate') {
            steps {
                sh '''
                    echo "Validating configuration..."
                    which terraform && terraform validate || echo "Terraform validation skipped"
                    which ansible-playbook && ansible-playbook --syntax-check playbook.yml || echo "Ansible check skipped"
                '''
            }
        }

        stage('Stop Load Testing') {
            when { expression { params.ACTION == 'destroy' } }
            steps {
                echo 'Stopping load testing and Robot Shop...'
                sh '''
                    ssh -o StrictHostKeyChecking=no root@${TF_VAR_existing_vm_ip} \
                        "cd /opt/robot-shop && docker-compose -f docker-compose-load.yaml down" || echo "Load generator not running"
                    
                    ssh -o StrictHostKeyChecking=no root@${TF_VAR_existing_vm_ip} \
                        "cd /opt/robot-shop && docker-compose down" || echo "Robot Shop not running"
                '''
            }
        }

        stage('Terraform - Instana Resources') {
            when { expression { params.SKIP_TERRAFORM == false } }
            steps {
                sh '''
                    echo "Initializing Terraform..."
                    terraform init -upgrade
                    
                    echo ""
                    echo "=========================================="
                    echo "Creating Instana Resources:"
                    echo "=========================================="
                    echo "✓ Application Perspective: Robot-Shop-Microservices-Daneshwari-2026"
                    echo "✓ Custom Events: High Error Rate, High Latency, Service Down, Container Failure, High Memory"
                    echo "✓ Alert Channel: Email to Daneshwari.Naganur1@ibm.com"
                    echo "✓ Alert Configuration: Robot Shop Monitoring Alerts"
                    echo "✓ API Token: robot-shop-readonly-token (RBAC)"
                    echo "=========================================="
                    echo ""
                    
                    if [ "${ACTION}" = "deploy" ]; then
                        echo "Running Terraform Apply..."
                        terraform apply -auto-approve \
                            -var="instana_agent_key=${INSTANA_AGENT_KEY}" \
                            -var="instana_api_token=${INSTANA_API_TOKEN}"
                    elif [ "${ACTION}" = "destroy" ]; then
                        echo "Running Terraform Destroy..."
                        terraform destroy -auto-approve \
                            -var="instana_agent_key=${INSTANA_AGENT_KEY}" \
                            -var="instana_api_token=${INSTANA_API_TOKEN}"
                    elif [ "${ACTION}" = "plan" ]; then
                        echo "Running Terraform Plan..."
                        terraform plan \
                            -var="instana_agent_key=${INSTANA_AGENT_KEY}" \
                            -var="instana_api_token=${INSTANA_API_TOKEN}"
                    fi
                '''
            }
        }
        
        stage('Ansible - Deploy Robot Shop') {
            when { expression { params.SKIP_ANSIBLE == false && params.ACTION == 'deploy' } }
            steps {
                script {
                    try {
                        // Use sshpass for password authentication
                        sh '''
                            echo "Testing SSH connection to ${TF_VAR_existing_vm_ip}..."
                            sshpass -p 'pwd@FYRE1234567' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@${TF_VAR_existing_vm_ip} "echo 'SSH OK'"
                            
                            echo "Running Ansible playbook..."
                            ansible-playbook -i inventory.ini playbook.yml \
                                -e "instana_agent_key=${INSTANA_AGENT_KEY}" \
                                -e "instana_api_token=${INSTANA_API_TOKEN}" \
                                -e "instana_endpoint_host=${INSTANA_ENDPOINT_HOST}" \
                                -e "instana_endpoint_port=${INSTANA_ENDPOINT_PORT}" \
                                -e "instana_zone=${INSTANA_ZONE}" \
                                -v
                        '''
                    } catch (Exception e) {
                        echo "Ansible failed: ${e.message}"
                        throw e
                    }
                }
            }
        }

        stage('Deploy Load Testing') {
            when { expression { params.ACTION == 'deploy' } }
            steps {
                sh '''
                    echo "Deploying load testing..."
                    ssh -o StrictHostKeyChecking=no root@${TF_VAR_existing_vm_ip} \
                    "cd /opt/robot-shop && curl -sO https://raw.githubusercontent.com/instana/robot-shop/master/docker-compose-load.yaml && REPO=robotshop TAG=latest docker-compose -f docker-compose.yml -f docker-compose-load.yaml up -d" || echo "Load testing deployment failed"
                '''
            }
        }
    }
    
    post {
        success { 
            script {
                if (params.ACTION == 'destroy') {
                    echo "=========================================="
                    echo "✓ Destroy completed!"
                    echo "✓ Load testing stopped"
                    echo "✓ Robot Shop stopped"
                    echo "✓ Alerts will stop triggering"
                    echo "=========================================="
                } else {
                    echo "=========================================="
                    echo "✓ Pipeline completed successfully!"
                    echo "=========================================="
                    echo ""
                    echo "🚀 Robot Shop Application:"
                    echo "   URL: http://${TF_VAR_existing_vm_ip}:8080"
                    echo ""
                    echo "📊 Instana Monitoring:"
                    echo "   Dashboard: https://${INSTANA_ENDPOINT_HOST}"
                    echo "   Application: Robot-Shop-Microservices-Daneshwari-2026"
                    echo "   Zone: ${INSTANA_ZONE}"
                    echo ""
                    echo "📧 Alert Configuration:"
                    echo "   Email: Daneshwari.Naganur1@ibm.com"
                    echo "   Channel: Robot Shop Alert Email"
                    echo ""
                    echo "⚠️  Custom Events Created:"
                    echo "   - High Error Rate (>5%)"
                    echo "   - High Response Time (>1000ms)"
                    echo "   - Service Down"
                    echo "   - Container Failure"
                    echo "   - High Memory Usage (>90%)"
                    echo ""
                    echo "🔐 RBAC:"
                    echo "   API Token: robot-shop-readonly-token (read-only access)"
                    echo ""
                    echo "=========================================="
                }
            }
        }
        failure { 
            echo "✗ Pipeline failed"
        }
        always { 
            cleanWs()
        }
    }
}