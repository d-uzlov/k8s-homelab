
# Add line duplication

Command name: Copy Line Down

# Disable yaml autoformat

In settings search for:
```js
@id:editor.formatOnSave @lang:yaml formatOnSave
```

# YAML formatting

Install: Kubernetes YAML Formatter

Add to `settings.json` to the first level (doesn't work at language level):

```json
    "kubernetes-yaml-formatter.includeDocumentStart": true,
    "kubernetes-yaml-formatter.compactSequenceIndent": true,
```

# convenient tab switching

Edit the following shortcuts for `Ctrl + Tab` and `Ctrl + Shift + Tab` switching:

```js
workbench.action.nextEditor
workbench.action.previousEditor

// or

workbench.action.nextEditorInGroup
workbench.action.previousEditorInGroup
```

# Convenient switch from terminal to editor

Press `` Ctrl + ` `` to switch from editor to terminal,
and use the same shortcut to switch back.

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
Add the following to the `settings.json`

```json
"terminal.integrated.commandsToSkipShell": [
  "-workbench.action.showCommands", // f1
  "-workbench.action.terminal.findNext", // f3
  "-workbench.action.debug.start", // f5
  "-workbench.action.focusNextPart", // f6
  "-workbench.action.quickOpen", // ctrl + P
  "-workbench.action.terminal.goToRecentDirectory", // ctrl + G
  "-workbench.action.terminal.scrollToTopAccessibleView", // ctrl + Home
  "-workbench.action.terminal.scrollToTop", // ctrl + Home
  "-workbench.action.terminal.scrollToBottomAccessibleView", // ctrl + Home
  "-workbench.action.terminal.scrollToBottom", // ctrl + Home
]
```

Search for the key combination in the shortcut settings
and select `Copy Command ID` to find and disable other commands if needed.

# Disable CRLF

Add the following to the `settings.json`:

```json
{
    "files.eol": "\n",
}
```

References:
- https://medium.com/bootdotdev/how-to-get-consistent-line-breaks-in-vs-code-lf-vs-crlf-e1583bf0f0b6
