#!/usr/bin/env python3
"""
Pexip Management Node Password Generator

This script generates properly hashed passwords for Pexip Infinity management node configuration:
- Web interface password (Django-style PBKDF2-SHA256)
- OS admin password (Linux-style SHA-512)

Usage:
    Interactive mode:
        ./generate_passwords.py

    Non-interactive mode:
        ./generate_passwords.py --web-password "your_web_password" --admin-password "your_admin_password"

    Generate JSON output:
        ./generate_passwords.py --json

    Generate tfvars output:
        ./generate_passwords.py --tfvars
"""

import argparse
import json
import sys
from passlib.hash import pbkdf2_sha256, sha512_crypt

def generate_django_password(password):
    """Generate a Django-style password hash using PBKDF2-SHA256."""
    ROUNDS = 36000
    return pbkdf2_sha256.using(rounds=ROUNDS).hash(password)

def generate_linux_password(password):
    """Generate a Linux-style SHA-512 password hash."""
    ROUNDS = 656000
    return sha512_crypt.using(rounds=ROUNDS).hash(password)

def validate_password(password):
    """Validate password requirements."""
    if len(password) < 4:
        raise ValueError("Password must be at least 4 characters long")
    return True

def get_password_interactive(prompt):
    """Get and validate password input interactively."""
    while True:
        try:
            password = input(f"Enter {prompt}: ")
            validate_password(password)
            confirm = input(f"Confirm {prompt}: ")
            if password != confirm:
                print("Passwords do not match. Please try again.")
                continue
            return password
        except ValueError as e:
            print(f"Error: {e}")

def generate_hashes(web_password, admin_password):
    """Generate both password hashes."""
    try:
        validate_password(web_password)
        validate_password(admin_password)

        return {
            "web_hash": generate_django_password(web_password),
            "admin_hash": generate_linux_password(admin_password)
        }
    except ValueError as e:
        print(f"Error: {e}")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="Generate Pexip management node password hashes")
    parser.add_argument("--web-password", help="Web interface password")
    parser.add_argument("--admin-password", help="OS admin password")
    parser.add_argument("--json", action="store_true", help="Output in JSON format")
    parser.add_argument("--tfvars", action="store_true", help="Output in Terraform tfvars format")
    args = parser.parse_args()

    # Interactive mode if no passwords provided
    if not (args.web_password and args.admin_password):
        print("=== Pexip Management Node Password Generator ===\n")
        web_password = get_password_interactive("web interface password")
        admin_password = get_password_interactive("OS admin password")
    else:
        web_password = args.web_password
        admin_password = args.admin_password

    hashes = generate_hashes(web_password, admin_password)

    # Output format
    if args.json:
        print(json.dumps(hashes, indent=2))
    elif args.tfvars:
        print(f"""
mgmt_node_admin_password_hash = "{hashes['admin_hash']}"
mgmt_node_web_password_hash   = "{hashes['web_hash']}"
""".strip())
    else:
        print("\n=== Generated Password Hashes ===")
        print(f"\nWeb Interface Password Hash (Django-style):")
        print(f"{hashes['web_hash']}")
        print(f"\nOS Admin Password Hash (Linux-style):")
        print(f"{hashes['admin_hash']}")
        print("\nStore these passwords securely!")

if __name__ == "__main__":
    main()
