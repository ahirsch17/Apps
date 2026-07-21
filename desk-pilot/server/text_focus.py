"""Detect when the user clicked into something typable on Windows."""

from __future__ import annotations

TEXT_FIELD_TYPES = {
    "EditControl",
    "DocumentControl",
    "ComboBoxControl",
}

NON_TEXT_TYPES = {
    "ButtonControl",
    "HyperlinkControl",
    "MenuItemControl",
    "ListItemControl",
    "TreeItemControl",
    "TabItemControl",
    "SliderControl",
    "CheckBoxControl",
    "RadioButtonControl",
    "ToolBarControl",
    "ThumbControl",
}

CLASS_HINTS = (
    "edit",
    "input",
    "search",
    "omnibox",
    "monaco",
    "textarea",
    "textbox",
    "address",
    "combo",
    "find",
    "query",
    "url",
    "candidat",
    "prompt",
    "chat",
)


def _accepts_text_input(control) -> bool:
    if control is None:
        return False

    try:
        if not control.IsKeyboardFocusable:
            return False
    except Exception:
        return False

    if control.ControlTypeName in NON_TEXT_TYPES:
        return False

    if control.ControlTypeName in TEXT_FIELD_TYPES:
        return True

    class_name = (control.ClassName or "").lower()
    control_name = (control.Name or "").lower()
    automation_id = (control.AutomationId or "").lower()

    if any(hint in class_name for hint in CLASS_HINTS):
        return True
    if any(hint in automation_id for hint in CLASS_HINTS):
        return True
    if any(word in control_name for word in ("search", "address", "find", "type")):
        return True

    try:
        value_pattern = control.GetValuePattern()
        if value_pattern is not None and not value_pattern.IsReadOnly:
            return True
    except Exception:
        pass

    try:
        if control.GetTextPattern() is not None:
            return True
    except Exception:
        pass

    return False


def _candidate_controls():
    import uiautomation as auto
    from pynput.mouse import Controller as MouseController

    seen = set()
    candidates = []

    def add(control) -> None:
        if control is None:
            return
        try:
            key = control.NativeWindowHandle, control.ControlTypeName, control.ClassName
        except Exception:
            key = id(control)
        if key in seen:
            return
        seen.add(key)
        candidates.append(control)

    add(auto.GetFocusedControl())

    x, y = MouseController().position
    under_cursor = auto.ControlFromPoint(int(x), int(y))
    add(under_cursor)

    parent = under_cursor
    for _ in range(8):
        if parent is None:
            break
        add(parent)
        parent = parent.GetParentControl()

    return candidates


def pc_text_field_is_focused() -> bool:
    try:
        for control in _candidate_controls():
            if _accepts_text_input(control):
                return True
            try:
                for child, _ in control.Walk(includeTop=False, maxDepth=2):
                    if _accepts_text_input(child):
                        return True
            except Exception:
                continue
        return False
    except Exception:
        return False


def describe_focus_target() -> str:
    try:
        import uiautomation as auto
        from pynput.mouse import Controller as MouseController

        focused = auto.GetFocusedControl()
        x, y = MouseController().position
        under = auto.ControlFromPoint(int(x), int(y))

        def fmt(control) -> str:
            if control is None:
                return "none"
            return (
                f"{control.ControlTypeName}"
                f" class={control.ClassName!r}"
                f" focusable={control.IsKeyboardFocusable}"
            )

        return f"focus={fmt(focused)} cursor={fmt(under)} accepts={pc_text_field_is_focused()}"
    except Exception as exc:
        return f"error={exc}"
