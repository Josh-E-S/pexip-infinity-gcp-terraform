# Pexip Password Generation Tool

This tool generates properly hashed passwords required for the Pexip Infinity management node.

## Requirements
- Python 3.6 or later
- passlib library (`pip install -r requirements.txt`)

## Usage

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

## Password Requirements
- Minimum length: 4 characters (recommended: 12+ characters)
- Web interface uses Django-style PBKDF2-SHA256 hashing
- OS admin uses Linux-style SHA-512 hashing

## Security Notes
- Store generated passwords securely
- Use strong passwords (minimum 4 characters, recommended 12+)
- Keep the plain text passwords safe - you'll need them to log in
- Never commit password files to version control

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
