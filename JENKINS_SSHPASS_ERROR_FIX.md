# Jenkins SSH Authentication Fix

## Problem
Jenkins pipeline was failing with SSH authentication errors:
- `sshpass: command not found` (exit code 127)
- `ansible: command not found` (exit code 127)

## Root Cause
The Jenkins agent (running on macOS) did not have `sshpass` or `ansible` commands available in its PATH.

## Solution
Use `expect` command for SSH password authentication, which is typically pre-installed on macOS systems.

## Changes Made

### 1. Added VM Password Environment Variable
```groovy
environment {
    VM_PASSWORD = 'pwd@FYRE1234567'
}
```

### 2. Updated SSH Commands to Use Expect
Instead of:
```bash
sshpass -e ssh root@IP "command"
```

Now using:
```bash
expect << 'EOF'
spawn ssh -o StrictHostKeyChecking=no root@${TF_VAR_existing_vm_ip} "command"
expect {
    "password:" { send "${VM_PASSWORD}\r"; exp_continue }
    eof
}
EOF
```

### 3. Updated Ansible Command
Changed from:
```bash
ansible-playbook -i inventory.ini playbook.yml
```

To:
```bash
/usr/local/bin/ansible-playbook -i inventory.ini playbook.yml \
    -e "ansible_password=${VM_PASSWORD}"
```

## Stages Updated

### Stage: Stop Load Testing
- Uses `expect` for SSH commands to stop Docker containers

### Stage: Ansible - Deploy Robot Shop  
- Tests SSH connection using `expect`
- Runs ansible-playbook with full path and password parameter

### Stage: Deploy Load Testing
- Uses `expect` for SSH command to deploy load testing

## How Expect Works

1. **spawn**: Starts the SSH command
2. **expect**: Waits for password prompt
3. **send**: Sends the password followed by carriage return
4. **exp_continue**: Continues expecting more output
5. **eof**: Waits for end of file (command completion)

## Verification Steps

1. **Commit and Push Changes**
   ```bash
   git add Jenkinsfile
   git commit -m "Use expect for SSH password authentication"
   git push origin main
   ```

2. **Rebuild Jenkins Pipeline**
   - Go to Jenkins dashboard
   - Click on your pipeline job
   - Click "Build with Parameters"
   - Select ACTION: `deploy`
   - Click "Build"

3. **Monitor Console Output**
   - Watch for "Testing SSH connection" message
   - Verify SSH connection succeeds
   - Check Ansible playbook execution

## Expected Output

```
Testing SSH connection to 9.30.220.114...
spawn ssh -o StrictHostKeyChecking=no root@9.30.220.114 echo 'SSH OK'
SSH OK

Running Ansible playbook with password...
PLAY [Configure VM, Install Docker, Instana Agent and Deploy Robot Shop]
...
```

## Alternative Solutions (If Expect Fails)

### Option 1: Install sshpass on Jenkins Agent
```bash
# On macOS
brew install hudochenkov/sshpass/sshpass
```

### Option 2: Use SSH Key Authentication
1. Generate SSH key pair
2. Add public key to VM's `~/.ssh/authorized_keys`
3. Add private key to Jenkins credentials
4. Update Jenkinsfile to use SSH key

### Option 3: Run Ansible Locally
Install Ansible on Jenkins agent:
```bash
brew install ansible
```

## Troubleshooting

### If expect command not found
```bash
# Check if expect is installed
which expect

# Install if needed (macOS)
brew install expect
```

### If SSH still fails
1. Verify VM password is correct
2. Check VM allows password authentication:
   ```bash
   ssh root@9.30.220.114
   # Check /etc/ssh/sshd_config
   # PasswordAuthentication should be yes
   ```

3. Test SSH manually:
   ```bash
   ssh -o StrictHostKeyChecking=no root@9.30.220.114
   ```

### If Ansible fails
1. Verify ansible-playbook path:
   ```bash
   which ansible-playbook
   ```

2. Update Jenkinsfile with correct path

3. Check inventory.ini has correct password

## Files Modified
- [`Jenkinsfile`](Jenkinsfile:1) - Updated SSH authentication method

## Related Documentation
- [`JENKINS_SETUP_GUIDE.md`](JENKINS_SETUP_GUIDE.md) - Jenkins setup instructions
- [`JENKINS_ERROR_FIX.md`](JENKINS_ERROR_FIX.md) - Previous Jenkins fixes
- [`inventory.ini`](inventory.ini:1) - Ansible inventory with VM credentials

## Commit History
1. `67e1df8` - Fix SSH authentication using sshpass with environment variable
2. `2876ace` - Use Ansible for all SSH operations instead of sshpass
3. `d8b863b` - Use expect for SSH password authentication and full ansible-playbook path