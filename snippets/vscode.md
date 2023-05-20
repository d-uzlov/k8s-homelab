
# Add line duplication

Command name: Copy Line Down

# Disable yaml autoformat

In settings search for:
@id:editor.formatOnSave @lang:yaml formatOnSave

# YAML formatting

Install: Kubernetes YAML Formatter

Add to settings.json to first level (doesn't work at language level):
```json
    "kubernetes-yaml-formatter.includeDocumentStart": true,
    "kubernetes-yaml-formatter.compactSequenceIndent": true,
```

# convenient tab switching

workbench.action.nextEditor
workbench.action.previousEditor

or

workbench.action.nextEditorInGroup
workbench.action.previousEditorInGroup

# Convenient switch from terminal to editor

{
  "key": "ctrl+oem_3",
  "command": "workbench.action.focusActiveEditorGroup",
  "when": "terminalFocus"
}
