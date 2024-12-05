
# Recommended extensions

Format: `Name - "First-line-from-description"`

- Code Spell Checker - "Spelling checker for source code"
- Kubernetes - "Develop, deploy and debug Kubernetes applications"
- Better YAML Formatter - "A better YAML formatter"
- Go - "Rich Go language support for Visual Studio Code"

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

# Hotkeys setup

Add hotkeys into array in `keybindings.json`:
`C:/Users/username/AppData/Roaming/Code/User/keybindings.json`

```json
// general
{
  "key": "ctrl+s",
  "command": "-workbench.action.files.save"
},
{
  "key": "ctrl+s",
  "command": "workbench.action.files.saveWithoutFormatting"
},
{
  "key": "ctrl+k ctrl+shift+s",
  "command": "-workbench.action.files.saveWithoutFormatting"
},
{
  "key": "ctrl+d",
  "command": "-editor.action.addSelectionToNextFindMatch",
  "when": "editorFocus"
},
{
  "key": "ctrl+d",
  "command": "editor.action.copyLinesDownAction",
  "when": "editorTextFocus && !editorReadonly"
},
// tab switching
{
    "key": "ctrl+tab",
    "command": "-workbench.action.quickOpenNavigateNextInEditorPicker",
    "when": "inEditorsPicker && inQuickOpen"
},
{
    "key": "ctrl+tab",
    "command": "-workbench.action.quickOpenPreviousRecentlyUsedEditorInGroup",
    "when": "!activeEditorGroupEmpty"
},
{
    "key": "ctrl+tab",
    "command": "workbench.action.nextEditor"
},
{
  "key": "ctrl+shift+tab",
  "command": "workbench.action.previousEditor"
},
{
  "key": "ctrl+shift+tab",
  "command": "-workbench.action.quickOpenNavigatePreviousInEditorPicker",
  "when": "inEditorsPicker && inQuickOpen"
},
{
  "key": "ctrl+shift+tab",
  "command": "-workbench.action.quickOpenLeastRecentlyUsedEditorInGroup",
  "when": "!activeEditorGroupEmpty"
},
// terminal:
{
  "key": "ctrl+oem_3", // Ctrl + `, switches to terminal by default, but doesn't go back
  "command": "workbench.action.focusActiveEditorGroup", // switch from terminal back to editor
  "when": "terminalFocus"
},
{
  "key": "ctrl+shift+k",
  "command": "workbench.action.terminal.kill",
  "when": "terminalFocus"
},
{
  "key": "ctrl+shift+enter",
  "command": "workbench.action.terminal.runSelectedText",
  "when": "editorFocus"
},
{
  "key": "ctrl+shift+enter", // disable default
  "command": "-editor.action.insertLineBefore",
  "when": "editorTextFocus && !editorReadonly"
},
{
  "key": "ctrl+oem_comma", // this blocks `ctrl + ,` in terminal, and it can't be disabled via commandsToSkipShell
  "command": "-workbench.action.openSettings"
},
{
  "key": "shift+f6", // by default terminal does not get shift+f6
  "command": "workbench.action.focusPreviousPart",
  "when": "!terminalFocus"
},
{
  "key": "shift+f6",
  "command": "-workbench.action.focusPreviousPart"
},
{
  "key": "shift+f3", // by default shift + F3 brings search
  "command": "workbench.action.terminal.findPrevious",
  "when": "terminalFindFocused && terminalHasBeenCreated || terminalFindFocused && terminalProcessSupported"
},
{
  "key": "shift+f3",
  "command": "-workbench.action.terminal.findPrevious",
  "when": "terminalFindFocused && terminalHasBeenCreated || terminalFindFocused && terminalProcessSupported || terminalFocusInAny && terminalHasBeenCreated || terminalFocusInAny && terminalProcessSupported"
},
{
  "key": "alt+up",
  "command": "workbench.action.terminal.sendSequence",
  "when": "terminalFocus",
  "args": {
    "text": "\u001b[1;2P" // F13 for nano
  }
},
{
  "key": "alt+down",
  "command": "workbench.action.terminal.sendSequence",
  "when": "terminalFocus",
  "args": {
    "text": "\u001b[1;2Q" // F14 for nano
  }
},
// {
//   "key": "ctrl+backspace",
//   // default ctrl+backspace in terminal is ^H
//   // default "delete word" is ^W
//   // vscode maps ctrl backspace to ^W
//   // this breaks default nano settings
//   "command": "-workbench.action.terminal.sendSequence",
//   "when": "terminalFocus"
// },
// {
//   "key": "ctrl+delete",
//   // default ctrl+delete is ^[[3;5~
//   // default "delete next word" is M-D
//   // vscode maps ctrl+delete to M-D
//   // this breaks default nano settings
//   "command": "-workbench.action.terminal.sendSequence",
//   "when": "terminalFocus"
// },
```

# Fix signals for terminal

Disable the following in settings: `terminal.integrated.allowChords`.

Then either:
- enable `terminal.integrated.sendKeybindingsToShell`
- fill in custom `commandsToSkipShell` in `settings.json`
- - `C:/Users/username/AppData/Roaming/Code/User/settings.json`

```json
"terminal.integrated.commandsToSkipShell": [
  "-workbench.action.showCommands", // f1
  "-workbench.action.terminal.findNext", // f3
  "-workbench.action.debug.start", // f5
  "-workbench.action.focusNextPart", // f6
  "-workbench.action.quickOpen", // ctrl + P
  "-workbench.action.quickOpenView", // ctrl + Q
  "-workbench.action.togglePanel", // ctrl + J
  "-workbench.action.terminal.goToRecentDirectory", // ctrl + G
  "-workbench.action.terminal.scrollToTopAccessibleView", // ctrl + Home
  "-workbench.action.terminal.scrollToTop", // ctrl + Home
  "-workbench.action.terminal.scrollToBottomAccessibleView", // ctrl + Home
  "-workbench.action.terminal.scrollToBottom", // ctrl + Home
  "-workbench.action.focusPreviousPart", // shift + F6
  "-workbench.action.terminal.findPrevious", // shift + F3
  "-workbench.action.toggleFullScreen", // shift + F11
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

# Fold all blocks on a page

`ctrl + K, ctrl + 0` to fold everything.
Instead of `0` you can use other numbers fo fold only until N level.

`ctrl + K, ctrl + J` to unfold everything.
