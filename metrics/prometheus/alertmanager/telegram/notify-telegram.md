
# Alertmanager telegram integration

References:
- Possibly better CRDs: https://github.com/prometheus-operator/prometheus-operator/issues/7117

# Telegram setup

First, create telegram bot:

- Search for `@BotFather`
- Select `/newbot`
- Follow instructions
- Save bot token

```bash

botToken=
# example: botToken=1234567890:qwertyuiopasdfghj_klzxcvbnmqwertyui

mkdir -p ./metrics/prometheus/alertmanager/telegram/env/
 cat << EOF > ./metrics/prometheus/alertmanager/telegram/env/telegram-secret.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: telegram-bot-token
stringData:
  token: $botToken
EOF

```

Then create a chat thet you want to use for notifications:
- https://gist.github.com/nafiesl/4ad622f344cd1dc3bb1ecbe468ff9f8a

It can be a private chat between you and the bot:

```bash

# Send a message to bot, and get it via APi
chatId=$(curl https://api.telegram.org/bot$botToken/getUpdates | jq .result[0].message.chat.id)

echo $chatId

 cat << EOF > ./metrics/prometheus/alertmanager/telegram/routes/telegram-route-info.yaml
- op: add
  path: /spec/receivers/0/telegramConfigs/0/chatID
  value: $chatId
EOF

```

It can be a group chat:

```bash

# Send a message to group chat, or group chat topic
# copy message link
# https://t.me/c/{group_chat_id}/{group_topic_id}/{message_id}
# for example
# https://t.me/c/2101334281/2/2
# Here 2101334281 is group chat ID _suffix_
# prepend -100 to get full chat ID

chatId=-1002101334281
messageThreadId=2

 cat << EOF > ./metrics/prometheus/alertmanager/telegram/routes/telegram-route-info.yaml
- op: add
  path: /spec/receivers/0/telegramConfigs/0/chatID
  value: $chatId
- op: add
  path: /spec/receivers/0/telegramConfigs/0/messageThreadID
  value: $messageThreadId
EOF

```

Repeat this for:
- `telegram-route-info.yaml`
- `telegram-route-warning.yaml`
- `telegram-route-critical.yaml`

# Deploy

```bash

kl -n prometheus apply -k ./metrics/prometheus/alertmanager/telegram/
kl kustomize ./metrics/prometheus/alertmanager/telegram/
kl -n prometheus get AlertmanagerConfig
kl -n prometheus describe AlertmanagerConfig -l alertmanager.prometheus.io/integration=telegram

```

# Cleanup

```bash
kl -n prometheus delete -k ./metrics/prometheus/alertmanager/telegram/
```
