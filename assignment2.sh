#!/bin/bash

# Function to print status messages
print_status() {
    echo "==== $1 ===="
}

# Check and configure the network interface
configure_network() {
    print_status "Configuring network interface..."
    
    # Update netplan configuration if necessary
    if ! grep -q "192.168.16.21" /etc/netplan/*.yaml; then
        echo "Updating netplan configuration..."
        cat <<EOL | sudo tee /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      addresses:
        - 192.168.16.21/24
      dhcp4: no
EOL
        sudo netplan apply
        echo "Network configuration updated."
    else
        echo "Network is already configured."
    fi

    # Update /etc/hosts file for server1
    if ! grep -q "192.168.16.21 server1" /etc/hosts; then
        echo "Updating /etc/hosts file..."
        echo "192.168.16.21 server1" | sudo tee -a /etc/hosts > /dev/null
    else
        echo "/etc/hosts file is already correct."
    fi
}

# Install Apache and Squid if not installed
install_software() {
    print_status "Installing software..."
    
    # Install apache2 if not installed
    if ! dpkg -l | grep -q apache2; then
        sudo apt update && sudo apt install -y apache2
        echo "Apache installed."
    else
        echo "Apache is already installed."
    fi

    # Install squid if not installed
    if ! dpkg -l | grep -q squid; then
        sudo apt install -y squid
        echo "Squid installed."
    else
        echo "Squid is already installed."
    fi

    # Ensure services are running
    sudo systemctl start apache2 squid
}

# Create user accounts as needed
create_users() {
    print_status "Creating user accounts..."

    # List of users to create with their SSH keys (replace with actual keys)
    declare -A users=(
        [dennis]="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"
        [aubrey]=""
        [captain]=""
        [snibbles]=""
        [brownie]=""
        [scooter]=""
        [sandy]=""
        [perrier]=""
        [cindy]=""
        [tiger]=""
        [yoda]=""
    )

    for user in "${!users[@]}"; do
        if id "$user" &>/dev/null; then
            echo "$user already exists."
        else
            sudo useradd -m -s /bin/bash "$user"
            echo "$user created with home directory."
            if [[ -n "${users[$user]}" ]]; then
                mkdir -p "/home/$user/.ssh"
                echo "${users[$user]}" >> "/home/$user/.ssh/authorized_keys"
                chown -R "$user:$user" "/home/$user/.ssh"
                chmod 700 "/home/$user/.ssh"
                chmod 600 "/home/$user/.ssh/authorized_keys"
                echo "$user's SSH key added."
            fi

            # Add dennis to the sudo group for access control.
            if [[ "$user" == "dennis" ]]; then 
                sudo usermod -aG sudo "$user"
                echo "$user added to the sudo group."
            fi 
        fi 
    done 
}

# Main execution function 
main() {
    configure_network 
    install_software 
    create_users 
    print_status "All configurations complete!" 
}

# Run the main function 
main 
