output "public ip" {
    value = "${azurerm_public_ip.fxbattle.ip_address}"
}

output "url" {
    value = "${azurerm_dns_a_record.fxbattle.name}"
}