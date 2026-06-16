#!/bin/bash

enable_srv() {
SERVICE=${1}
dinitctl enable ${SERVICE}
dinitctl start ${SERVICE}
}
enable_srv turnstiled

pacman -S firewalld-dinit pipewire-dinit

