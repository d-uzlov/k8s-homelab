https://doc.owncloud.com/server/10.11/admin_manual/installation/docker/

# owncloud

Generate:
helm template /var/tmp/ocis-charts/charts/ocis/ > install-2023-03-01-c030fea79a86cf18e1d5c225ee2e51cf3d1ee5ac.yaml --set externalDomain=owncloud.example.duckdns.org

Deploy:
kl apply -k ./cloud/owncloud/
kl wait -n owncloud --for=condition=ready pods --all

kl -n owncloud exec deployments/owncloud -- cat /etc/apache2/apache2.conf
