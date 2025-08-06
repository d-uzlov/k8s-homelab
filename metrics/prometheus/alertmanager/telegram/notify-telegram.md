
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

- Send a message to group chat topic
- copy message link
- - format is: `https://t.me/c/{group_chat_id}/{group_topic_id}/{message_id}`
- - example: `https://t.me/c/2101334281/2/2`
- - Here `2101334281` is group chat ID _suffix_
- prepend `-100` to get full chat ID
- - example: `-1002101334281`
- [!!!] Don't forget to invite your bot to the group chat
- - You will need to start conversation with your bot to see it in the list of people to invite

```bash

chatId=
# example: chatId=-1002101334281

# fill messageThreadId from {group_topic_id} in the link
messageThreadId=

# You can create separate topics for different alerts, or show everything in a single thread

 cat << EOF > ./metrics/prometheus/alertmanager/telegram/env/telegram-receiver-info.yaml
- op: add
  path: /spec/receivers/0/telegramConfigs/0/chatID
  value: $chatId
- op: add
  path: /spec/receivers/0/telegramConfigs/0/messageThreadID
  value: $messageThreadId
EOF

 cat << EOF > ./metrics/prometheus/alertmanager/telegram/env/telegram-receiver-warning.yaml
- op: add
  path: /spec/receivers/0/telegramConfigs/0/chatID
  value: $chatId
- op: add
  path: /spec/receivers/0/telegramConfigs/0/messageThreadID
  value: $messageThreadId
EOF

 cat << EOF > ./metrics/prometheus/alertmanager/telegram/env/telegram-receiver-critical.yaml
- op: add
  path: /spec/receivers/0/telegramConfigs/0/chatID
  value: $chatId
- op: add
  path: /spec/receivers/0/telegramConfigs/0/messageThreadID
  value: $messageThreadId
EOF

```

# Deploy

```bash

kl apply -k ./metrics/prometheus/alertmanager/telegram/
kl -n prometheus get AlertmanagerConfig
kl -n prometheus describe AlertmanagerConfig -l alertmanager.prometheus.io/integration=telegram

```

# Cleanup

```bash
kl -n prometheus delete -k ./metrics/prometheus/alertmanager/telegram/
```
