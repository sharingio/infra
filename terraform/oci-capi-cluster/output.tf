output "oci_network_security_group_id" {
  value = oci_core_network_security_group.network_security_group.id
}

output "oci_network_subnet_id" {
  value = oci_core_subnet.subnet.id
}
