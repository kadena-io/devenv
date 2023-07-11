{ pkgs, lib, config, ... }:

let
  cfg = config.services.nginx;
  configFile = pkgs.writeText "nginx.conf" ''
    pid ${config.env.DEVENV_STATE}/nginx/nginx.pid;
    error_log stderr debug;
    daemon off;

    events {
      ${cfg.eventsConfig}
    }

    http {
      access_log off;
      client_body_temp_path ${config.env.DEVENV_STATE}/nginx/;
      proxy_temp_path ${config.env.DEVENV_STATE}/nginx/;
      fastcgi_temp_path ${config.env.DEVENV_STATE}/nginx/;
      scgi_temp_path ${config.env.DEVENV_STATE}/nginx/;
      uwsgi_temp_path ${config.env.DEVENV_STATE}/nginx/;

      ${cfg.httpConfig}
    }
  '';
in
{
  options.services.nginx = {
    enable = lib.mkEnableOption "nginx";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.nginx;
      defaultText = "pkgs.nginx";
      description = "The nginx package to use.";
    };

    httpConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "The nginx configuration.";
    };

    eventsConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "The nginx events configuration.";
    };

    configFile = lib.mkOption {
      type = lib.types.path;
      default = configFile;
      internal = true;
      description = "The nginx configuration file.";
    };
  };

  config = lib.mkIf cfg.enable {
    processes.nginx.exec = "${cfg.package}/bin/nginx -c ${cfg.configFile} -e /dev/stderr -p $PWD";

    enterShell = ''
      mkdir -p ${config.env.DEVENV_STATE}/nginx
    '';
  };
}
