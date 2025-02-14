
# Test that deployment works

```bash
kl get sc
kl get sc -o go-template --template "{{ range .items }}{{ .metadata.name }} {{ end }}"
kl get sc iscsi -o jsonpath='{.parameters.fsType}'

mkdir -p ./test/pvc/env/

for sc in $(kl get sc -o go-template --template "{{ range .items }}{{ .metadata.name }} {{ end }}"); do
sed \
  -e "s/AUTOREPLACE_TEST_NAME/test-sc-$storage_class_name/" \
  -e "s/AUTOREPLACE_STORAGE_CLASS/$sc/" \
  ./test/pvc/test.template.yaml \
  > ./test/pvc/env/test-$sc.yaml
done

kl create ns test-pvc
# create all test pods in bulk
cat ./test/pvc/env/test-* | kl -n test-pvc apply -f -
# make sure that PVCs are provisioned
kl get pvc
# make sure that test pods are running
kl get pod -o wide

(cd ./test/pvc/env/ && ls test-* | sed s~.yaml~~g)
# select one of the tests to get details
testName=
echo $testName

# if pvc is not getting provisioned, check events
# also check controller logs
kl -n test-pvc describe pvc $testName
kl -n test-pvc describe pod -l app=$testName

# check mounted file system for all test pods
for testName in $(cd ./test/pvc/env/ && /bin/ls test-* | sed s~.yaml~~); do
kl -n test-pvc exec deployments/$testName -- mount | grep /mnt/data
kl -n test-pvc exec deployments/$testName -- df -h /mnt/data
kl -n test-pvc exec deployments/$testName -- touch /mnt/data/test-file
kl -n test-pvc exec deployments/$testName -- ls -laF /mnt/data
done

# explore container
kl -n test-pvc exec deployments/$testName -it -- sh
# explore container as root
testPod=$(kl -n test-pvc get pod -l app=$testName -o name)
kl -n test-pvc debug $testPod -it --image docker.io/alpine:3.17.3 --container debug --profile sysadmin --target alpine --custom ./storage/democratic-csi-generic/proxy/storage-classes/debug-container.yaml -- sh
kl -n test-pvc attach $testPod -c debug -it -- sh
# https://kubernetes.io/blog/2024/08/22/kubernetes-1-31-custom-profiling-kubectl-debug/

# cleanup resources
cat ./test/pvc/env/test-* | kl -n test-pvc delete -f -
```
