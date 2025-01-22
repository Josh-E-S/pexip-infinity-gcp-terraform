locals {
  # Firewall rule names
  firewall_prefix = "pexip-infinity"
  
  # Management ports
  mgmt_ports = {
    ssh          = "22"
    provisioning = "8443"
    teams_hub    = "40000-49999"
    dns          = "53"
    ntp          = "123"
    syslog       = "514"
    smtp         = "587"
    ldap         = "389,636"
  }

  # Service ports
  service_ports = {
    media  = "33000-39999"
    sip    = "5060-5061"
    h323   = "1720,1719"
    teams  = "40000-49999"
    gmeet  = "19302-19309"
  }

  # Node type tags
  tags = {
    management  = "pexip-mgmt"
    transcoding = "pexip-transcoding"
    proxy       = "pexip-proxy"
  }

  # All the port configurations stay the same but organized by service
  ports = {
    # Media ports (shared by all conferencing nodes)
    media = {
      start = 40000
      end   = 49999
    }

    # Management node services
    management = {
      admin = {
        tcp = ["443"]          # Web admin interface
      }
      ssh = {
        tcp = ["22"]           # SSH access
      }
      provisioning = {
        tcp = ["8443"]         # Conferencing node provisioning
      }
      teams_hub = {
        tcp = ["5671"]         # Teams Connector Azure Event Hub (AMQPS)
      }
      dns = {
        tcp = ["53"]           # DNS over TCP
        udp = ["53"]           # DNS queries
      }
      ntp = {
        udp = ["123"]          # NTP time sync
      }
      syslog = {
        udp = ["514"]          # Syslog messages
      }
      smtp = {
        tcp = ["587"]          # SMTP mail
      }
      ldap = {
        tcp = ["389", "636"]   # LDAP and LDAPS
      }
    }

    # Conferencing node services
    conferencing = {
      # SIP signaling
      sip = {
        tcp = ["5060", "5061"]  # SIP and SIP/TLS
        udp = ["5060"]          # SIP UDP
      }

      # H.323 signaling
      h323 = {
        tcp = ["1720", "33000-39999"]  # H.323/H.245
        udp = ["1719"]                 # H.323 RAS
      }

      # Platform integrations
      teams = {
        tcp = ["443"]          # Teams signaling
        udp = ["50000-54999"]  # Teams Media to VM scaleset instance SRTP/SRTCP
      }
      gmeet = {
        tcp = ["443"]          # Google Meet signaling
        udp = ["19302-19309"]  # SRTP/SRTCP
      }
    }

    # Internal communication between nodes
    internal = {
      udp = ["500"]           # ISAKMP (IPsec)
      protocols = ["esp"]     # IPsec ESP (IP Protocol 50)
    }
  }
}
