# Pexip Configuration Tools

This directory contains tools to help configure your Pexip Infinity deployment.

## Password Generation Tool

This tool generates properly hashed passwords required for the Pexip Infinity management node.

### Requirements
- Python 3.6 or later
- passlib library (`pip install -r requirements.txt`)

### Usage

1. Interactive mode (recommended for first use):
```bash
./generate_passwords.py
```

2. Generate tfvars format:
```bash
./generate_passwords.py --tfvars > passwords.auto.tfvars
```

3. Non-interactive mode:
```bash
./generate_passwords.py --web-password "secure123" --admin-password "secure456" --tfvars
```

## SSH Key Configuration

You have two options for SSH key configuration:

### Option 1: Let Terraform Generate SSH Keys (Recommended)
If you don't provide an SSH key, Terraform will:
1. Generate a secure 4096-bit RSA key pair
2. Store the private key in Google Secret Manager as `[project-id]-pexip-ssh-private-key`
3. Configure the public key on all instances

To retrieve the private key after deployment:
1. Go to Google Cloud Console > Security > Secret Manager
2. Find the secret named `[project-id]-pexip-ssh-private-key`
3. Access the latest version
4. Save the private key to a secure location (DO NOT commit to version control)

### Option 2: Provide Your Own SSH Key
1. Generate an SSH key pair locally:
```bash
ssh-keygen -t rsa -b 4096 -C "admin" -f ./pexip-ssh-key
```

2. Format the public key for Terraform:
```bash
echo "$(cat pexip-ssh-key.pub) admin" > ssh_public_key.txt
```

3. Use in your Terraform configuration:
```hcl
ssh_public_key = file("./ssh_public_key.txt")
```

## Password Requirements
- Minimum length: 4 characters (recommended: 12+ characters)
- Web interface uses Django-style PBKDF2-SHA256 hashing
- OS admin uses Linux-style SHA-512 hashing

## Security Notes
- Store generated passwords and SSH keys securely
- Use strong passwords (minimum 4 characters, recommended 12+)
- Keep private keys and plain text passwords safe
- Never commit sensitive files to version control
- The following files are automatically ignored by .gitignore:
  - *.pem, *.key, *.pub (SSH keys)
  - passwords.auto.tfvars (password files)
  - Other common sensitive file patterns

## Example Usage

1. Generate password hashes:
```bash
cd tools
pip install -r requirements.txt
./generate_passwords.py --tfvars > ../passwords.auto.tfvars
```

2. Use the generated hashes in your Terraform configuration:
```hcl
# passwords.auto.tfvars
mgmt_node_admin_password_hash = "$6$rounds=656000$..."
mgmt_node_web_password_hash   = "$pbkdf2-sha256$36000$..."
```

The management node will automatically configure these passwords during initialization.
