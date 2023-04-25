## Workflow Schema

The brains behind the `dialog-wheel` program reside in a JSON data structure
resembling a state machine. The program encourages the separation of the
UX flow from the control layer of the UI.

### The Workflow

- `version`: (required) "1.0.0"
- `dialog`: (optional) subdocument to define common dialog parameters
- `screens`: (required) subdocument of `screen` objects
- `start`: (required) string of the starting `screen`
- `exit`: (optional) string of the "exit capture" `screen`
- `error`: (optional) string of the "uncaught error" `screen`
- `handlers`: (optional) string or array of strings handlers
- `includes`: (optional) array of scripts for the control layer

__JSON__
``` json
{
    "version": "1.0.0",
    "dialog": {
        "backtitle": "Example App"
    },
    "screens": {
        "Message": {
            "type": "msgbox",
            "properties": {
                "text": "This is some text"
            }
        }
    },
    "start": "Message"
}
```

__YAML__
``` yaml
version: "1.0.0"
dialog:
    backtitle: Example App
screens:
    Message:
        type: msgbox
        properties:
            text: This is some text
start: Message
```

### Inclusions

- `directory`: (optional) relative pr absolute path of script folders
- `file`: (required) relative or absolute path of scripts who control the app

__JSON__
```
"includes": [
    {
        "directory": "exmaples",
        "file": "application.sh"
    }
]
```

__YAML__
```
includes:
- directory: examples
  file: application.sh
```

### Screen

- `type`: (required) Various screen types
- `capture_into`: (optional) JSON path string to set the internal state
- `properties`: (required) subdocument of properties in for screen types
- `dialog`: (optional) subdocument of dialog properties
- `next`: (optional) string or conditional
- `back`: (optional) string or conditional
- `handlers`: (optional) string or array of string handlers

__JSON__
```
"Message Box": {
    "dialog": {
        "colors": true,
        "title": "Alert"
    },
    "type": "msgbox",
    "properties": {
        "text": "This is just some message notification."
    },
    "next": "Some Other Page"
}
```

__YAML__
``` yaml
"Message Box":
    dialog:
        colors: True
        title: Alert
    type: msgbox
    properties:
        text: This is just some message notification.
    next: Some Other Page
```

### Handlers

The `dialog-wheel` state machine will acknowledge the following events:

- `ok`: This is the `exit 0` response from `screen`
- `cancel`: This is the `exit 1` response from `screen`
- `capture_info`: For screens that have `capture_into` set
- `help`: For screens that have `help-button` defined
- `extra`: For screens that have `extra-button` defined
- `esc`: When the escape key is pressed
- `timeeout`: When the dialog timesout
- `error`: When an uncaught error was thrown (defaules to `exit` in workflow)

Default handlers are provided by the `dialog-wheel` program already in scope:

- `wheel::handlers::ok`: will set the next
- `wheel::handlers::cancel`: will pop the stack of visited `screen`s
- `wheel::handlers::capture_into`: will set the state value `capture_into`
- `wheel::handlers::capture_into::argjson`: will set the state value `capture_into` but raw JSON value
- `wheel::handlers::esc`: will push `exit` screen in the visited stack
- `wheel::handlers::error`: will push `error` screen in the visited stack
- `wheel::screens::hub::selection`: will set the menu item as `next`
- `wheel::screens::checklist::list`: will set the checklist type values as an array
- `wheel::screens::checklist::field`: will set the checklist type values as fields of boolean flags

You can define your own custom handlers as functions in included scripts.

