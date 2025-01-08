
# Alertmanager telegram integration

References:
- Possibly better CRDs: https://github.com/prometheus-operator/prometheus-operator/issues/7117

# Telegram setup

1. Obtain telegram bot token and chat ID:
- https://gist.github.com/nafiesl/4ad622f344cd1dc3bb1ecbe468ff9f8a

2. Send a message to bot to create a private chat with the bot.

3. Create telegram secret and receiver config:

```bash
# get chat ID
botToken=
# example: botToken=1234567890:qwertyuiopasdfghj_klzxcvbnmqwertyui
chatId=$(curl https://api.telegram.org/bot$botToken/getUpdates | jq .result[0].message.chat.id)
echo $chatId

mkdir -p ./metrics/prometheus/alertmanager/telegram/env/
cat << EOF > ./metrics/prometheus/alertmanager/telegram/env//telegram-secret.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: telegram-bot-token
stringData:
  token: $botToken
EOF

cat << EOF > ./metrics/prometheus/alertmanager/env/telegram/alert-manager-telegram.yaml
- op: add
  path: /spec/receivers/0/telegramConfigs/0/chatID
  value: $chatId
EOF

```

# Deploy

```bash

kl -n prometheus apply -k ./metrics/prometheus/alertmanager/telegram/
kl -n prometheus get AlertmanagerConfig
kl -n prometheus describe AlertmanagerConfig -l alertmanager.prometheus.io/integration=telegram

```

# Cleanup

```bash
kl -n prometheus delete -k ./metrics/prometheus/alertmanager/telegram/
```
