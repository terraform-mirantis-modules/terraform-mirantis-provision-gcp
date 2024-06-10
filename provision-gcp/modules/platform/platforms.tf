
locals {
  // this is the idea of @jcarrol who put this into a lib map. Here we steal his idea
  lib_platform_definitions = {
    "ubuntu_22.04" : {
      "family" : "ubuntu-2204-lts",
      "project" : "ubuntu-os-cloud",
      "filter" : "name = ubuntu-2204-jammy-v*",
      "interface" : "eth0",
      "connection" : "ssh",
      "ssh_user" : "ubuntu",
      "ssh_port" : 22,
    },
    "windows_2022" : {
      "family" : "windows-2022",
      "project" : "windows-cloud",
      "filter" : "name = windows-server-2022-dc-v*",
      "interface" : "Ethernet 3"
      "connection" : "winrm",
      "ssh_user" : "miradmin",
      "winrm_useHTTPS" : true,
      "winrm_insecure" : true,
    },
  }
}
