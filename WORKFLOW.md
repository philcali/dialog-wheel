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

An inclusion defines the relative or absolute path to a script that defines
a function or set of functions to be used in the workflow definition. An
inclusion can consist of `handler` functions, arbitrary scripts invoked in
`custom` screens, `event` handlers, and everything in between. The inclusion
are basically user-defined functions that are invoked by `dialog-wheel`.

- `directory`: (optional) relative pr absolute path of script folders
- `file`: (required) relative or absolute path of scripts who control the app

__JSON__
``` json
"includes": [
    {
        "directory": "exmaples",
        "file": "application.sh"
    }
]
```

__YAML__
``` yaml
includes:
- directory: examples
  file: application.sh
```

### Screen

The screen object contains the static definition for rendering a single page
node in an otherwise expansive decision tree. 

- `type`: (required) Various screen types
- `capture_into`: (optional) JSON path string to set the internal state
- `properties`: (required) subdocument of properties in for screen types
- `dialog`: (optional) subdocument of dialog properties
- `next`: (optional) string or conditional
- `back`: (optional) string or conditional
- `handlers`: (optional) string or array of string handlers
- `clear_history`: (optional) flag that signals the workflow engine to clear the stack tracking visited nodes.

__JSON__
``` json
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

### Screen Types

The `dialog-wheel` is a hub and spoke model TUI workflow engine. So which
are the *hubs* and which are the *spokes*? This section defines the 
screen types and their properties.

#### Hub

The `hub` is how to render a "menu" whose actions are supposed to take a user
to different screens (thus, the name `hub`). The following properties are
additive to the general screen properties:

- `items`: (required) an array of `item` documents
- `text`: (optional) string of text before the menu is rendered
- `menu_height`: (optional) integer of how many rows of the inner menu

To get the most out of a menu, set the `handlers.ok` to be the 
`wheel::screens::hub::selection` method. Upon selecting a menu item, the
`next_screen` will be overridden to its value.

__JSON__

``` json
"Main Menu": {
    "type": "hub",
    "properties": {
        "items": [
            {
                "name": "First Page",
                "description": "This is the first page"
            },
            {
                "name": "Second Page",
                "description": "This is the second page"
            }
        ]
    },
    "handlers": {
        "ok": "wheel::screens::hub::selection"
    }
}
```

__YAML__
``` yaml
Main Menu:
    type: hub
    properties:
        items:
        - name: First Page
          description: This is the first page
        - name: Second Page
          description: This is the second page
    handlers:
        ok: wheel::screens::hub::selection
```

![Main Menu](images/documentation/hub.png)

#### Message

The `msgbox` type is basically an alert message. The key properties
for a `msgbox` are:

- `text`: (required) string of text

__JSON__
``` json
"Message": {
    "type": "msgbox",
    "properties": {
        "text": "Hi"
    }
}
```

__YAML__
``` yaml
Message:
    type: msgbox
    properties:
        text: Hi
```

![Message Box](images/documentation/msgbox.png)

#### Confirmation

The `yesno` type is the confirmation dialog box. The key properties
for `yesno` are:

- `text`: (required) string of text

Note: that if `dialog` is the underlying TUI rendering program, then all
of the `dialog` options are availble.

__JSON__

``` json
"Confirmation": {
    "type": "yesno",
    "properties": {
        "text": "Do you like bananas?"
    }
}
```

__YAML__
``` yaml
Confirmation:
    type: yesno
    properties:
        text: Do you like bananas?
```

![Confirmation](images/documentation/yesno.png)

#### Input

The `inputbox` is just a plain text input element. The key properties
for an `inputbox` is:

- `capture_into`: (optional) state field to store the value
- `text`: (optional) string label for the input box

__JSON__
``` json
"Username": {
    "type": "input",
    "capture_into": "user.name",
    "properties": {
        "text": "Enter your username"
    }
}
```

__YAML__
``` yaml
Username:
    type: input
    capture_into: user.name
    properties:
        text: Enter your username
```

![Username](images/documentation/input.png)

__State__

``` yaml
user:
    name: philcali
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
