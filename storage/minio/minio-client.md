
# install mc

Requirements:
- [~/.bashrc.d](../../docs/bash-setup.md#add-bashrc-directory)

```bash

curl https://dl.min.io/client/mc/release/linux-amd64/mc \
  --create-dirs \
  -o ~/minio-binaries/mc

chmod +x ~/minio-binaries/mc

 cat << "EOF" > ~/.bashrc.d/0-minio.sh
export PATH=$PATH:$HOME/minio-binaries/

alias mc="mc --disable-pager"
EOF

 cat << "EOF" > ~/.bashrc.d/0-minio-completion.sh
complete -C $HOME/minio-binaries/mc mc
EOF

. ~/.bashrc.d/0-minio.sh

mc --version

mc alias list

# remove default aliases
mc alias remove s3
mc alias remove play
mc alias remove gcs

```

# configure connection to server

```bash

 minio_alias=b2788
 # for local installation in docker add port 9000
 connection_url=http://minio.example.com/
 access_key=
 secret_key=
mc alias set "$connection_name" "$connection_url" "$access_key" "$secret_key"

mc admin info $connection_name

 cat << EOF > ~/.bashrc.d/0-minio-default-alias.sh
minio_alias=$minio_alias
EOF

```

# Test

```bash

mc admin user ls ${minio_alias}
mc admin policy ls ${minio_alias}

# create bucket
mc mb ${minio_alias}/test-bucket

mc cp --recursive ./storage/minio ${minio_alias}/test-bucket/minio-docs

mc ls ${minio_alias}
mc ls ${minio_alias}/test-bucket/minio-docs
mc ls ${minio_alias}/test-bucket --recursive --summarize
mc tree ${minio_alias}/test-bucket
mc tree ${minio_alias}/test-bucket --files

# remove bucket
mc rb ${minio_alias}/test-bucket --force

```

References:
- https://docs.min.io/community/minio-object-store/reference/minio-mc.html

# users with limited access to object store

```bash

user_name=test-$(openssl rand -hex 10)
user_secret=$(openssl rand -hex 20)
mc admin user add ${minio_alias} $user_name $user_secret

bucket_name=limited-$user_name
policy_name=limited-$user_name

mc mb ${minio_alias}/$bucket_name

mc admin policy create ${minio_alias} $policy_name /dev/stdin << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${bucket_name}/*",
        "arn:aws:s3:::${bucket_name}"
      ]
    }
  ]
}
EOF

mc admin policy attach ${minio_alias} $policy_name --user $user_name
mc admin policy entities ${minio_alias} --policy $policy_name

mc alias set "${minio_alias}-via-$user_name" "$connection_url" "$user_name" "$user_secret"

# test access to own bucket
echo hello | mc pipe ${minio_alias}-via-$user_name/$bucket_name/hello-file
mc ls ${minio_alias}-via-$user_name/$bucket_name
mc cat ${minio_alias}-via-$user_name/$bucket_name/hello-file

# should get "Access Denied" error when working with other buckets
mc ls ${minio_alias}-via-$user_name/mynewbucket

# cleanup
mc admin policy detach ${minio_alias} $policy_name --user $user_name
mc admin policy rm ${minio_alias} $policy_name
mc admin user rm ${minio_alias} $user_name
mc rb ${minio_alias}/$bucket_name --force

```

References:
- https://medium.com/@740643ax6/how-to-limit-user-to-access-only-1-bucket-in-minio-05a94be94206
