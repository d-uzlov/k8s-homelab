#!/bin/bash

if [ "$1" = "worker" ]; then
  join=$(sudo kubeadm token create --print-join-command)
  echo "sudo $join --node-name "'$(hostname --fqdn)'
  exit 0
fi

if [ "$1" = "master" ]; then
  join=$(sudo kubeadm token create --print-join-command)
  cp_cert=$(sudo kubeadm init phase upload-certs --upload-certs | grep -vw -e certificate -e Namespace)
  echo "sudo $join --node-name "'$(hostname --fqdn)'" --control-plane --certificate-key $cp_cert"
  exit 0
fi

echo unsupported argument: "'$1'"
