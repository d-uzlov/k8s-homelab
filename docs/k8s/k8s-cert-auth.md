
# Add non-admin users to the cluster

References:
- https://aungzanbaw.medium.com/a-step-by-step-guide-to-creating-users-in-kubernetes-6a5a2cfd8c71
- https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/
- https://kubernetes.io/docs/reference/access-authn-authz/authentication/

Contents:

1. [Decide on user name](#1-decide-on-user-name)
2. [User generates a private key and a CSR](#2-user-generates-a-private-key-and-a-csr-certificate-signing-request)
3. [Admin creates a signed certificate based on CSR](#3-admin-creates-a-signed-certificate-based-on-csr)
4. [Admin sets up permissions for the user](#4-admin-sets-up-permissions-for-the-user)
5. [Admin makes the k8s API server publicly accessible](#5-admin-makes-the-k8s-api-server-publicly-accessible)
6. [Admin sets up kubeconfig for the user](#6-admin-sets-up-kubeconfig-for-the-user)
7. [User sets up local configuration](#7-user-sets-up-local-configuration)

## 1. Decide on user name

Names starting with `system:` are reserved by k8s.
Any other names are allowed.

Usernames are supposed to be unique, groups can be shared.

```bash
short_user_name=john-smith
full_user_name=user:friends:$short_user_name
user_group=users:friends
```

Prefixes proposed here (`user:friends`, `users:friends`) don't mean anything, you can choose your own.

## 2. User generates a private key and a CSR (certificate signing request)

```bash
mkdir -p /tmp/k8s-auth/
rm -rf /tmp/k8s-auth/"$short_user_name".key /tmp/k8s-auth/"$short_user_name".csr
openssl genrsa -out /tmp/k8s-auth/"$short_user_name".key 2048
openssl req -new -key /tmp/k8s-auth/"$short_user_name".key -out /tmp/k8s-auth/"$short_user_name".csr -subj "/CN=$full_user_name/O=$user_group"
```

If needed, you can add several groups like this: `-subj "/CN=name/O=group-one/O=another-group"`.

Groups are optional, you can omit them. This guide only sets a group for completeness sake.

User should then transfer the generated `.csr` file to cluster admin.

## 3. Admin creates a signed certificate based on CSR

```bash
# path is the same for convenience when testing these instructions locally
csr_path=/tmp/k8s-auth/"$short_user_name".csr
csr_name="$short_user_name"

# verify that CSR is valid
openssl req -noout -in "$csr_path" -verify
openssl req -noout -in "$csr_path" -text
openssl req -noout -in "$csr_path" -subject

# save user name and organization somewhere
# in case you need to re-adjust permissions later
mkdir -p ./_env/external-users/
echo -n "$short_user_name: " >> ./_env/external-users/list.txt
openssl req -noout -in "$csr_path" -subject >> ./_env/external-users/list.txt

kl delete csr "$csr_name"
kl apply --server-side -f - << EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: $csr_name
spec:
  request: $(cat "$csr_path" | base64 | tr -d "\n")
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 31104000 # 360 days
  usages:
  - client auth
EOF

# check that everything is correct once again
kl describe csr "$csr_name"

kl certificate approve "$csr_name"
kl wait csr "$csr_name" --for=jsonpath='{.status.certificate}'

cert_path=./_env/external-users/"$short_user_name".crt
rm -rf "$cert_path"
kl get csr "$csr_name" -o jsonpath='{.status.certificate}' | base64 -d > "$cert_path"
# inspect the certificate
openssl x509 -noout -in "$cert_path" -text
openssl x509 -noout -in "$cert_path" -subject
```

## 4. Admin sets up permissions for the user

References:
- https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- https://kubernetes.io/docs/concepts/security/rbac-good-practices/
- https://kubernetes.io/docs/concepts/security/pod-security-admission/

The only way to revoke access to the cluster is to remove role bindings,
so we create a separate role binding for each user, even though we could use groups.

```bash
# add convenience role
kl apply -f ./docs/k8s/auth-convenience/

namespace=test-namespace
kl create ns "$namespace"
# enforce=baseline disables access to host machine:
#     hostPath volumes, hostNetwork, sysctl, etc.
kl label ns "$namespace" pod-security.kubernetes.io/enforce=baseline
kl label ns "$namespace" "rbac/has-external-access=true"
kl label ns "$namespace" "rbac-user/${short_user_name}=edit"
kl describe ns "$namespace"

# enable convenience role to view safe cluster-wide resources
kl apply -f - << EOF
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: convenience-for-${short_user_name}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-convenience
subjects:
- kind: User
  name: $full_user_name
EOF

# give this user access to selected namespace
# repeat if you want more namespaces
kl apply -f - << EOF
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: edit-for-${short_user_name}
  namespace: $namespace
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: edit
subjects:
- kind: User
  name: $full_user_name
EOF
```

## 5. Admin makes the k8s API server publicly accessible

Check your current apiserver address:

```bash
echo $(kl config view --raw -o jsonpath='{.clusters[?(@.name == "'"$current_cluster_name"'")].cluster.server}')
```

If this address is accessible from all the places you want to use kubectl, that's good.

For proper all-over-the-world access you will need to have the standard setup:
NAT port forwarding, IPv6, tunnel, whatever.
In either setup you will need to use DNS, because apiserver is verified against the name you used to access it.

If currently you are using a private IP or private DNS for apiserver address,
you will probably need to add the new domain name into apiserver certificate.

It's possible to bypass this check by specifying TLS name that's different from access name
but I think that's a bad practice, so I like to avoid it.

Here is now to add a new domain name into apiserver certificate:

```bash
mkdir -p ./_env/
kl -n kube-system get configmap kubeadm-config -o jsonpath='{.data.ClusterConfiguration}' > ./_env/kubeadm-cluster-configuration.yaml

# You need to have `yq` v4 installed: https://github.com/kislyuk/yq
# or you can do this manually instead
new_domain=k8s.example.duckdns.org
yq -i '.apiServer.certSANs += ["'"$new_domain"'"]' ./_env/kubeadm-cluster-configuration.yaml
# you can repeat this several times to add several domains

cp_node1=m1.k8s.lan
ssh $cp_node1 rm -rf kubeadm-cluster-configuration.yaml
scp ./_env/kubeadm-cluster-configuration.yaml "$cp_node1":kubeadm-cluster-configuration.yaml
# kubeadm will not re-create certificate if it already exists, so let's move cert files
ssh $cp_node1 sudo mv /etc/kubernetes/pki/apiserver.{crt,key} ~
ssh $cp_node1 sudo kubeadm init phase certs apiserver --config kubeadm-cluster-configuration.yaml
ssh $cp_node1 sudo kubeadm init phase upload-config kubeadm --config kubeadm-cluster-configuration.yaml

# do we need this? It seems to be working without it just fine
kl -n kube-system delete pod -l component=kube-apiserver
```

References:
- https://blog.scottlowe.org/2019/07/30/adding-a-name-to-kubernetes-api-server-certificate/

## 6. Admin sets up kubeconfig for the user

```bash
# extract certificate authority from existing config
kconf_current_cluster=kubernetes
cluster_ca_path=./_env/external-users/cluster-ca.pem
kl config view --raw -o jsonpath='{.clusters[?(@.name == "'"$kconf_current_cluster"'")].cluster.certificate-authority-data}' |
  base64 -d > "$cluster_ca_path"
# if you use public address in current kubeconfig, extract it
cluster_public_address=$(kl config view --raw -o jsonpath='{.clusters[?(@.name == "'"$kconf_current_cluster"'")].cluster.server}')
# if cluster apiserver address in your config is not public, create one and set the variable manually

# these values are for user convenience, they don't affect connection or RBAC
kconf_user=$short_user_name
kconf_cluster=$(echo "$cluster_public_address" | sed -e s,https://,, -e s,:.*,,)
kconf_context=${kconf_user}@${kconf_cluster}

new_kubeconfig=./_env/external-users/$short_user_name-kconf.yaml
rm -rf "$new_kubeconfig"
kubectl --kubeconfig "$new_kubeconfig" config set-credentials "$kconf_user" --embed-certs --client-certificate "$cert_path"
kubectl --kubeconfig "$new_kubeconfig" config set-cluster "$kconf_cluster" --embed-certs --certificate-authority "$cluster_ca_path" --server "$cluster_public_address"
kubectl --kubeconfig "$new_kubeconfig" config set-context "$kconf_context" --cluster "$kconf_cluster" --user "$kconf_user"
kubectl --kubeconfig "$new_kubeconfig" config use-context "$kconf_context"
```

Admin should then transfer the new kubeconfig file to user.

## 7. User sets up local configuration

Inject your private key into the config:

```bash
# path to kubeconfig you got from admin
new_kubeconfig=
kubectl --kubeconfig "$new_kubeconfig" config set-credentials "$short_user_name" --embed-certs --client-key /tmp/k8s-auth/"$short_user_name".key
```

Check access to the cluster:

```bash
# list global cluster resources
kubectl --kubeconfig "$new_kubeconfig" get node
kubectl --kubeconfig "$new_kubeconfig" get sc
kubectl --kubeconfig "$new_kubeconfig" get ns
# check which namespaces are available to you
kubectl --kubeconfig "$new_kubeconfig" get ns -l "rbac-user/${short_user_name}"
kubectl --kubeconfig "$new_kubeconfig" describe ns -l "rbac-user/${short_user_name}"
```

You can now deploy stuff in available namespace(s).

You can create an alias for this config for easier access.
For example, use `createKubectlAlias` from [Kubectl completion](./kubectl-tips.md#bash-completion):

```bash
# execute this in terminal, or add to bashrc
createKubectlAlias kl "$new_kubeconfig"
```

Alternatively, if you already have `kl` alias and want to continue using it,
you can merge your new kubeconfig with the old one:

```bash
# check which kubeconfig you are currently using
alias kl
# set to kubeconfig path from the alias
old_kubeconfig=
cp "$old_kubeconfig" "$old_kubeconfig".bak
merged_kconf=$(KUBECONFIG="$old_kubeconfig":"$new_kubeconfig" kubectl config view --flatten)
echo "$merged_kconf" > "$old_kubeconfig"

# you can now switch between clusters from old and new kubeconfig files
kl config get-contexts
kl config use-context <context_name>
```
