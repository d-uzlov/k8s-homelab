#!/bin/bash

echo generating join info...
join=$(sudo kubeadm token create --print-join-command)
cp_cert=$(sudo kubeadm init phase upload-certs --upload-certs | grep -vw -e certificate -e Namespace)

echo
echo join worker:
echo "sudo $join --node-name "'$(hostname --fqdn)'

echo
echo join master:
echo "sudo $join --node-name "'$(hostname --fqdn)'" --control-plane --certificate-key $cp_cert"
