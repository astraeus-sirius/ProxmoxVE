#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/astraeus-sirius/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# Co-Author: MickLesk, michelroegl-brunner
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.elastic.co/

APP="Elasticsearch"
var_tags="search"
var_cpu="2"
var_ram="2048"
var_disk="8"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /etc/apt/sources.list.d/elasticsearch-8.x.list ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating ${APP}"
  $STD apt-get update
  $STD apt-get -y upgrade
  msg_ok "Updated Successfully"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9200${CL}"

msg_info "Installing Dependencies inside container"
lxc-attach -n "$CT_ID" -- bash -c 'apt-get update && apt-get install -y apt-transport-https curl gnupg'
msg_ok "Installed Dependencies inside container"

msg_info "Importing Elasticsearch GPG key inside container"
lxc-attach -n "$CT_ID" -- bash -c 'curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg'
msg_ok "Imported Elasticsearch GPG key inside container"

msg_info "Adding Elasticsearch repository inside container"
lxc-attach -n "$CT_ID" -- bash -c 'echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" > /etc/apt/sources.list.d/elasticsearch-8.x.list'
msg_ok "Added Elasticsearch repository inside container"

msg_info "Updating package lists inside container"
lxc-attach -n "$CT_ID" -- bash -c 'apt-get update'
msg_ok "Package lists updated inside container"

msg_info "Installing Elasticsearch inside container"
lxc-attach -n "$CT_ID" -- bash -c 'apt-get install -y elasticsearch'
msg_ok "Elasticsearch installed inside container"

msg_info "Enabling and starting Elasticsearch service inside container"
lxc-attach -n "$CT_ID" -- bash -c 'systemctl daemon-reload && systemctl enable --now elasticsearch'
msg_ok "Elasticsearch service enabled and started inside container"

motd_ssh
customize

msg_info "Cleaning up inside container"
lxc-attach -n "$CT_ID" -- bash -c 'apt-get -y autoremove && apt-get -y autoclean'
msg_ok "Cleaned up inside container"

trap 'exit_script' EXIT
trap 'post_update_to_api "failed" "$BASH_COMMAND"' ERR
trap 'post_update_to_api "failed" "INTERRUPTED"' SIGINT
trap 'post_update_to_api "failed" "TERMINATED"' SIGTERM
