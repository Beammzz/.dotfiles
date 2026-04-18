{ config, ... }: {
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
    validateSopsFiles = false;

    secrets = {
      cloudflare_apiToken = {};
      pihole_password = {};
      beszel_key = {};
      beszel_token = {};
      beszel_hubUrl = {};
      wireguard_privateKey = {};
      wireguard_presharedKey = {};
      wireguard_addresses = {};
      wireguard_provider = {};
      wireguard_type = {};
      wireguard_region = {};
      suwayomi_user = {};
      suwayomi_password = {};
      nextcloud_redisPassword = {};
      homepage_jellyfin_key = {};
      homepage_jellyseerr_key = {};
      homepage_suwayomi_username = {};
      homepage_suwayomi_password = {};
      homepage_qbittorrent_username = {};
      homepage_qbittorrent_password = {};
      homepage_prowlarr_key = {};
      homepage_sonarr_key = {};
      homepage_radarr_key = {};
      homepage_pihole_key = {};
      homepage_gitea_key = {};
      homepage_beszel_username = {};
      homepage_beszel_password = {};
    };

    templates = {
      "traefik.env".content = ''
        CF_DNS_API_TOKEN=${config.sops.placeholder.cloudflare_apiToken}
      '';

      "pihole.env".content = ''
        FTLCONF_webserver_api_password=${config.sops.placeholder.pihole_password}
      '';

      "beszel.env".content = ''
        KEY=${config.sops.placeholder.beszel_key}
        TOKEN=${config.sops.placeholder.beszel_token}
        HUB_URL=${config.sops.placeholder.beszel_hubUrl}
      '';

      "gluetun.env".content = ''
        VPN_SERVICE_PROVIDER=${config.sops.placeholder.wireguard_provider}
        VPN_TYPE=${config.sops.placeholder.wireguard_type}
        WIREGUARD_PRIVATE_KEY=${config.sops.placeholder.wireguard_privateKey}
        WIREGUARD_PRESHARED_KEY=${config.sops.placeholder.wireguard_presharedKey}
        WIREGUARD_ADDRESSES=${config.sops.placeholder.wireguard_addresses}
        SERVER_REGIONS=${config.sops.placeholder.wireguard_region}
      '';

      "suwayomi.env".content = ''
        BASIC_AUTH_USERNAME=${config.sops.placeholder.suwayomi_user}
        BASIC_AUTH_PASSWORD=${config.sops.placeholder.suwayomi_password}
      '';

      "nextcloud.env".content = ''
        REDIS_HOST_PASSWORD=${config.sops.placeholder.nextcloud_redisPassword}
      '';

      "homepage.env".content = ''
        HOMEPAGE_VAR_JELLYFIN_KEY=${config.sops.placeholder.homepage_jellyfin_key}
        HOMEPAGE_VAR_JELLYSEERR_KEY=${config.sops.placeholder.homepage_jellyseerr_key}
        HOMEPAGE_VAR_SUWAYOMI_USERNAME=${config.sops.placeholder.homepage_suwayomi_username}
        HOMEPAGE_VAR_SUWAYOMI_PASSWORD=${config.sops.placeholder.homepage_suwayomi_password}
        HOMEPAGE_VAR_QBITTORRENT_USERNAME=${config.sops.placeholder.homepage_qbittorrent_username}
        HOMEPAGE_VAR_QBITTORRENT_PASSWORD=${config.sops.placeholder.homepage_qbittorrent_password}
        HOMEPAGE_VAR_PROWLARR_KEY=${config.sops.placeholder.homepage_prowlarr_key}
        HOMEPAGE_VAR_SONARR_KEY=${config.sops.placeholder.homepage_sonarr_key}
        HOMEPAGE_VAR_RADARR_KEY=${config.sops.placeholder.homepage_radarr_key}
        HOMEPAGE_VAR_PIHOLE_KEY=${config.sops.placeholder.homepage_pihole_key}
        HOMEPAGE_VAR_GITEA_KEY=${config.sops.placeholder.homepage_gitea_key}
        HOMEPAGE_VAR_BESZEL_USERNAME=${config.sops.placeholder.homepage_beszel_username}
        HOMEPAGE_VAR_BESZEL_PASSWORD=${config.sops.placeholder.homepage_beszel_password}
      '';
    };
  };
}
