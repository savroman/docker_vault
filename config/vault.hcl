storage "consul" {
  address = "consul:8500"
  path    = "vault/"
}
listener "tcp" {
  	address = "0.0.0.0:8200"
    #tls_cert_file = "/config/server.crt"
    #tls_key_file = "/config/server.key"
  	tls_disable = 1
}
disable_mlock = true
