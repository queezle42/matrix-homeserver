{ lib, ... }:
with lib;

{
  # Should be at least 1.1 to prevent TLS downgrade attacks
  # But 1.2 should be supported by all homeservers, as well as the usual reverse proxies
  federation_client_minimum_tls_version = 1.2;

  # Generate thumbnails matching the resolution requested by clients
  dynamic_thumbnails = true;

  url_preview_enabled = true;
  url_preview_ip_range_blacklist = [
    "127.0.0.0/8"
    "10.0.0.0/8"
    "172.16.0.0/12"
    "192.168.0.0/16"
    "100.64.0.0/10"
    "192.0.0.0/24"
    "169.254.0.0/16"
    "192.88.99.0/24"
    "198.18.0.0/15"
    "192.0.2.0/24"
    "198.51.100.0/24"
    "203.0.113.0/24"
    "224.0.0.0/4"
    "::1/128"
    "fe80::/10"
    "fc00::/7"
    "2001:db8::/32"
    "ff00::/8"
    "fec0::/10"
  ];

  # Enable registration with registration tokens
  # Tokens can be issued by an admin:
  # https://matrix-org.github.io/synapse/latest/usage/administration/admin_api/registration_tokens.html
  enable_registration = true;
  registration_requires_token = true;

  # Benchmarked to take >0.5s on an AMD Ryzen 9 5900X
  bcrypt_rounds = 14;

  # Don't report anonymized usage statistics
  report_stats = false;

  trusted_key_servers = [
    { server_name = "matrix.org"; }
  ];
  suppress_key_server_warning = true;
}
