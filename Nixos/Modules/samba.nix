{...}: {
  services.samba = {
    enable = true;
    openFirewall = true;

    settings = {
      global = {
      	workgroup = "WORKGROUP";
        "server string" = "NixOS Samba Server";
        "netbios name" = "nixos";
        security = "user";

        "client min protocol" = "SMB2";
        "server min protocol" = "SMB2";

        "load printers" = "no";
        printing = "bsd";
        "printcap name" = "/dev/null";
        "disable spoolss" = "yes";
      };

      homes = {
        browseable = "no";
        writable = "yes";
        comment = "Home Directories";
        "valid users" = "%S";
        "create mask" = "0700";
        "directory mask" = "0700";
      };

      containers = {
        path = "/containers";
        browseable = "yes";
        writable = "yes";
        guest_ok = "no";
        comment = "Containers";
        "valid users" = "harumi";
        "create mask" = "0750";
        "directory mask" = "0750";
      };
    };
  };
}
