output "red_driver" {
  value = data.docker_network.bridge.driver
}

output "urls" {
  value = { for k, s in module.sitio : s.nombre => s.url }
}
