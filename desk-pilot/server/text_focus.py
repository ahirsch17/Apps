"""Detect when a text field is focused on Windows (search bars, inputs, etc.)."""

from __future__ import annotations

TEXT_FIELD_TYPES = {
    "EditControl",
    "DocumentControl",
    "ComboBoxControl",
}


def pc_text_field_is_focused() -> bool:
    try:
        import uiautomation as auto

        control = auto.GetFocusedControl()
        if control is None:
            return False

        if control.ControlTypeName not in TEXT_FIELD_TYPES:
            return False

        if not control.IsKeyboardFocusable:
            return False

        return True
    except Exception:
        return False
