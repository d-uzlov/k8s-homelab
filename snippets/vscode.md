
# Add line duplication

Command name: Copy Line Down

# Disable yaml autoformat

In settings search for:
```js
@id:editor.formatOnSave @lang:yaml formatOnSave
```

# YAML formatting

Install: Kubernetes YAML Formatter

Add to settings.json to first level (doesn't work at language level):
```json
    "kubernetes-yaml-formatter.includeDocumentStart": true,
    "kubernetes-yaml-formatter.compactSequenceIndent": true,
```

# convenient tab switching

```js
workbench.action.nextEditor
workbench.action.previousEditor

// or

workbench.action.nextEditorInGroup
workbench.action.previousEditorInGroup
```

# Convenient switch from terminal to editor

```js
{
  "key": "ctrl+oem_3",
  "command": "workbench.action.focusActiveEditorGroup",
  "when": "terminalFocus"
}
```

# Fix signals for terminal

Disable the following in settings:

```js
terminal.integrated.allowChords
```

Disable built-in commandsToSkipShell.
```json
"terminal.integrated.commandsToSkipShell": [
  "-editor.action.toggleTabFocusMode",
  "-notification.acceptPrimaryAction",
  "-notifications.hideList",
  "-notifications.hideToasts",
  "-workbench.action.closeQuickOpen"
]
```
