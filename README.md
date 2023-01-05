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
- `python3` (Optional for yaml support)

## How do I test this?

```
docker built -t dialog-test .
```

[1]: https://linuxcommand.org/lc3_adv_dialog.php