# Dialog Wheel

The bash [dialog][1] program is a powerful TUI tool, very suitable for single
page flows. The user of a `dialog` is on their own for establishing complex
workflows and decision trees.

Enter `dialog-wheel`, which is intended to allow a hub / spoke UX overlay
for dialog single page displays.

## What does wheel handle?

- State Management
- Page progression, backward and forward
- Required and optional forms

## What are wheel's dependencies?

- `dialog`
- `jq`
- `bc`
- `python3` (Optional for yaml support)

## How do I test this?


Build the container:

```
docker built -t dialog-wheel .
```

Run it like below:
```
docker run -it --rm --name dialog-wheel dialog-wheel -h
```

The `help` should print below
```
Usage main.sh - v1.0.0: Invoke a dialog wheel
Example usage: main.sh [-h] [-d state.json] [-o output.json] [-l app.log] [-L DEBUG|INFO|WARN|ERROR] [-s workflow.json] [< workflow.json]
  -o: Supply an output path for configured JSON
  -d: Supply a JSON file representative of the workflow state data
  -s: Supply a JSON file that represents the dialog flow
  -l: Supply a log source (defaults to /dev/null)
  -L: Supply a log level (defaults to INFO)
  -h: Prints out this help
```

To run the example application for `example.json`, simply mount the `$PWD` into `/wheel` like so:

```
docker run -it --rm --name dialog-wheel -v $PWD:/wheel dialog-wheel -s example.json -l application.log
```

[1]: https://linuxcommand.org/lc3_adv_dialog.php
