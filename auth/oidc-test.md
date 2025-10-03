
# authorization code grant

```bash

discovery_url=https://auth.example.com/.well-known/openid-configuration
client_id=
client_secret=

auth_endpoint=$(curl -sS $discovery_url | jq .authorization_endpoint -r)
token_endpoint=$(curl -sS $discovery_url | jq .token_endpoint -r)
userinfo_endpoint=$(curl -sS $discovery_url | jq .userinfo_endpoint -r)

# make sure that http://localhost:8080 is in the list of allowed redirect URLs
curl -v --data-urlencode "scope=openid" --data-urlencode "redirect_uri=http://localhost:8080" "$auth_endpoint?response_type=code&client_id=$client_id&state=RANDOM_STATE&nonce=RANDOM_NONCE"
# copy redirect URL from the output of the command above, and open it in browser

# start listener
python3 - <<'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer
class H(BaseHTTPRequestHandler):
    def do_GET(self):
        print("REQUEST PATH:", self.path)
        self.send_response(200); self.end_headers()
        self.wfile.write(b"OK, you can close this tab")
        raise SystemExit
HTTPServer(('localhost',8080), H).serve_forever()
PY

# after you allow auth in the browser, python will print access token

access_code=

token_bundle=$(curl -sS -X POST -u "$client_id:$client_secret" "$token_endpoint" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode grant_type=authorization_code --data-urlencode "code=$access_code" --data-urlencode "redirect_uri=http://localhost:8080")

echo $token_bundle | jq
echo $token_bundle | jq .access_token

curl -H "Authorization: Bearer $(echo $token_bundle | jq .access_token -r)" "$userinfo_endpoint"

```

# device code grant

```bash

# =========== public clients (without client secret) ===========

discovery_url=https://auth.example.com/.well-known/openid-configuration
client_id=

device_endpoint=$(echo $discovery_url | jq .device_authorization_endpoint -r)
token_endpoint=$(echo $discovery_url | jq .token_endpoint -r)

# request device node token
request_info=$(curl -sS --data-urlencode client_id=$client_id --data-urlencode "scope=offline_access openid" -X POST $device_endpoint)
# some applications provide verification_uri_complete, some require user to manually type user_code at verification_uri page, and some provide the complete value in verification_uri
echo $request_info | jq
# open the supplied link and confirm the access
# after access is granted, obtain access token and refresh token
device_code=$(echo $request_info | jq .device_code -r)
token=$(curl -sS --data-urlencode client_id=${client_id} --data-urlencode client_secret=$client_secret --data-urlencode grant_type=urn:ietf:params:oauth:grant-type:device_code --data-urlencode device_code=$device_code -X POST $token_endpoint)
echo $token | jq
# extract refresh token
refresh_token=$(echo $token | jq .refresh_token -r)
# try to refresh access token
curl -sS --data-urlencode client_id=$client_id --data-urlencode grant_type=refresh_token --data-urlencode refresh_token=$refresh_token --data-urlencode "scope=offline_access openid" -X POST $token_endpoint | jq

# =========== confidential clients (using client secret) ===========

discovery_url=https://auth.example.com/.well-known/openid-configuration
client_id=
client_secret=

device_endpoint=$(echo $discovery_url | jq .device_authorization_endpoint -r)
token_endpoint=$(echo $discovery_url | jq .token_endpoint -r)

request_info=$(curl -sS -u "$client_id:$client_secret" --data-urlencode "scope=offline_access openid" -X POST $device_endpoint)
echo $request_info | jq
device_code=$(echo $request_info | jq .device_code -r)
token=$(curl -sS -u "$client_id:$client_secret" --data-urlencode grant_type=urn:ietf:params:oauth:grant-type:device_code --data-urlencode device_code=$device_code -X POST $token_endpoint)
echo $token | jq
refresh_token=$(echo $token | jq .refresh_token -r)
curl -sS -u "$client_id:$client_secret" --data-urlencode grant_type=refresh_token --data-urlencode refresh_token=$refresh_token --data-urlencode "scope=offline_access openid" -X POST $token_endpoint | jq

```
