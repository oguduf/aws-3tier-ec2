#!/bin/bash
set -euxo pipefail

dnf update -y
dnf install -y docker git

systemctl enable docker
systemctl start docker

usermod -aG docker ec2-user

mkdir -p /opt/task-manager
chown ec2-user:ec2-user /opt/task-manager