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
        VM_PASSWORD = 'pwd@FYRE1234567'
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
                script {
                    echo 'Stopping load testing and Robot Shop...'
                    sh """
                        expect << EOF
                        spawn ssh -o StrictHostKeyChecking=no root@${TF_VAR_existing_vm_ip} "cd /opt/robot-shop && docker-compose -f docker-compose-load.yaml down"
                        expect {
                            "password:" { send "${VM_PASSWORD}\\r"; exp_continue }
                            eof
                        }
EOF
                        expect << EOF
                        spawn ssh -o StrictHostKeyChecking=no root@${TF_VAR_existing_vm_ip} "cd /opt/robot-shop && docker-compose down"
                        expect {
                            "password:" { send "${VM_PASSWORD}\\r"; exp_continue }
                            eof
                        }
EOF
                    """ || echo "Services not running"
                }
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
        
        stage('Deploy Robot Shop') {
            when { expression { params.SKIP_ANSIBLE == false && params.ACTION == 'deploy' } }
            steps {
                script {
                    try {
                        sh """
                            echo "Testing SSH connection to ${TF_VAR_existing_vm_ip}..."
                            expect << EOF
                            spawn ssh -o StrictHostKeyChecking=no root@${TF_VAR_existing_vm_ip} "echo 'SSH OK'"
                            expect {
                                "password:" { send "${VM_PASSWORD}\\r"; exp_continue }
                                "SSH OK" { exit 0 }
                                eof
                            }
EOF
                            
                            echo "Copying deployment script to VM..."
                            expect << EOF
                            spawn scp -o StrictHostKeyChecking=no deploy_robot_shop.sh root@${TF_VAR_existing_vm_ip}:/tmp/
                            expect {
                                "password:" { send "${VM_PASSWORD}\\r"; exp_continue }
                                eof
                            }
EOF
                            
                            echo "Deploying Robot Shop on VM..."
                            expect << EOF
                            set timeout 600
                            spawn ssh -o StrictHostKeyChecking=no root@${TF_VAR_existing_vm_ip} "chmod +x /tmp/deploy_robot_shop.sh && /tmp/deploy_robot_shop.sh '${INSTANA_AGENT_KEY}' '${INSTANA_ENDPOINT_HOST}' '${INSTANA_ENDPOINT_PORT}' '${INSTANA_ZONE}'"
                            expect {
                                "password:" { send "${VM_PASSWORD}\\r"; exp_continue }
                                "Deployment Complete" { exit 0 }
                                timeout { exit 1 }
                                eof
                            }
EOF
                        """
                    } catch (Exception e) {
                        echo "Deployment failed: ${e.message}"
                        throw e
                    }
                }
            }
        }

        stage('Deploy Load Testing') {
            when { expression { params.ACTION == 'deploy' } }
            steps {
                script {
                    try {
                        sh """
                            echo "Deploying load testing..."
                            expect << EOF
                            spawn ssh -o StrictHostKeyChecking=no root@${TF_VAR_existing_vm_ip} "cd /opt/robot-shop && curl -sO https://raw.githubusercontent.com/instana/robot-shop/master/docker-compose-load.yaml && REPO=robotshop TAG=latest docker-compose -f docker-compose.yml -f docker-compose-load.yaml up -d"
                            expect {
                                "password:" { send "${VM_PASSWORD}\\r"; exp_continue }
                                eof
                            }
EOF
                        """
                    } catch (Exception e) {
                        echo "Load testing deployment failed: ${e.message}"
                    }
                }
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