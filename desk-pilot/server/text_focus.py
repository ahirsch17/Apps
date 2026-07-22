"""Detect when the user clicked into a search bar or text field on Windows."""

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
    "PaneControl",
    "GroupControl",
    "WindowControl",
}

SEARCH_HINTS = (
    "search",
    "omnibox",
    "address",
    "find",
    "query",
    "url",
    "monaco",
    "input",
    "edit",
    "textbox",
    "textarea",
    "combo",
    "prompt",
    "chat",
)


def _has_search_hint(control) -> bool:
    class_name = (control.ClassName or "").lower()
    control_name = (control.Name or "").lower()
    automation_id = (control.AutomationId or "").lower()
    return any(
        hint in class_name or hint in automation_id or hint in control_name
        for hint in SEARCH_HINTS
    )


def _accepts_text_input(control, *, focused_control) -> bool:
    if control is None:
        return False

    try:
        if not control.IsKeyboardFocusable:
            return False
    except Exception:
        return False

    if control.ControlTypeName in NON_TEXT_TYPES:
        return False

    is_focused = control == focused_control
    has_hint = _has_search_hint(control)

    if control.ControlTypeName == "EditControl" and (is_focused or has_hint):
        return True

    if control.ControlTypeName == "ComboBoxControl" and (is_focused or has_hint):
        return True

    if control.ControlTypeName == "DocumentControl" and has_hint and is_focused:
        return True

    return has_hint and control.ControlTypeName in TEXT_FIELD_TYPES


def pc_text_field_is_focused() -> bool:
    try:
        import uiautomation as auto
        from pynput.mouse import Controller as MouseController

        focused = auto.GetFocusedControl()
        if _accepts_text_input(focused, focused_control=focused):
            return True

        x, y = MouseController().position
        under_cursor = auto.ControlFromPoint(int(x), int(y))
        if _accepts_text_input(under_cursor, focused_control=focused):
            return True

        if under_cursor is not None:
            try:
                for child, _ in under_cursor.Walk(includeTop=False, maxDepth=2):
                    if _accepts_text_input(child, focused_control=focused):
                        return True
            except Exception:
                pass

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
                f" name={control.Name!r}"
                f" focusable={control.IsKeyboardFocusable}"
            )

        return f"focus={fmt(focused)} cursor={fmt(under)} accepts={pc_text_field_is_focused()}"
    except Exception as exc:
        return f"error={exc}"
