provider "azurerm" {}

resource "azurerm_resource_group" "fxbattle" {
  name = "fxbattle"
  location = "${var.azure_region}"
}

# Create virtual network
resource "azurerm_virtual_network" "fxbattle" {
    name                = "fxbattleNetwork"
    address_space       = ["10.0.0.0/16"]
    location            = "${var.azure_region}"
    resource_group_name = "${azurerm_resource_group.fxbattle.name}"

    tags {
        environment = "${var.environment}"
    }
}

# Create subnet
resource "azurerm_subnet" "fxbattle" {
    name                 = "fxbattleSubnet"
    resource_group_name  = "${azurerm_resource_group.fxbattle.name}"
    virtual_network_name = "${azurerm_virtual_network.fxbattle.name}"
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "fxbattle" {
  name                         = "fxbattlePublicIp"
  location                     = "${var.azure_region}"
  resource_group_name          = "${azurerm_resource_group.fxbattle.name}"
  public_ip_address_allocation = "dynamic"

  tags {
    environment = "${var.environment}"
  }
}

# Security group
resource "azurerm_network_security_group" "fxbattle" {
    name                = "fxbattleSecurityGroup"
    location            = "${var.azure_region}"
    resource_group_name = "${azurerm_resource_group.fxbattle.name}"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "HTTP"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "HTTPS"
        priority                   = 1003
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags {
        environment = "${var.environment}"
    }
}

# Create network interface
resource "azurerm_network_interface" "fxbattle" {
    name                      = "fxbattleNIC"
    location                  = "${var.azure_region}"
    resource_group_name       = "${azurerm_resource_group.fxbattle.name}"
    network_security_group_id = "${azurerm_network_security_group.fxbattle.id}"

    ip_configuration {
        name                          = "fxbattleNICConfiguration"
        subnet_id                     = "${azurerm_subnet.fxbattle.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.fxbattle.id}"
    }

    tags {
        environment = "${var.environment}"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "fxbattle" {
  name                  = "fxbattleVM"
  location              = "${var.azure_region}"
  resource_group_name   = "${azurerm_resource_group.fxbattle.name}"
  network_interface_ids = ["${azurerm_network_interface.fxbattle.id}"]
  vm_size               = "${var.instance_size}"

  storage_os_disk {
      name              = "fxbattleBootDisk"
      caching           = "ReadWrite"
      create_option     = "FromImage"
      managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "18.04-LTS"
      version   = "latest"
  }

  os_profile {
      computer_name  = "fxbattle"
      admin_username = "azureuser"
  }

  os_profile_linux_config {
      disable_password_authentication = true
      ssh_keys {
          path     = "/home/azureuser/.ssh/authorized_keys"
          key_data = "${file(var.public_key_path)}"
      }
  }

  # Copy the chef solo recipe to the created instance
  provisioner "file" {
    source      = "chef"
    destination = "/home/azureuser"

    connection {
      user = "azureuser"
      private_key = "${file("~/.ssh/id_rsa")}"
    }
  }

  # Install the chef omnibus, and delegate to chef-solo
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get install -y build-essential",
      "curl -L https://www.opscode.com/chef/install.sh | sudo bash",
      "sudo /opt/chef/embedded/bin/gem install berkshelf --no-ri --no-rdoc",
      "cd /home/azureuser/chef",
      "sudo /opt/chef/embedded/bin/berks vendor --berksfile cookbooks/fxbattle/Berksfile cookbooks",
      "sudo chef-client -z -o fxbattle -c client.rb",
    ]

    connection {
      user = "azureuser"
      private_key = "${file("~/.ssh/id_rsa")}"
    }
  }

  tags {
      environment = "${var.environment}"
  }
}
