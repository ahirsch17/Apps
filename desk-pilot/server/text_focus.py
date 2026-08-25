"""Detect when the user clicked into a search bar or text field on Windows."""

from __future__ import annotations

TEXT_FIELD_TYPES = {
    "EditControl",
    "DocumentControl",
    "ComboBoxControl",
}


def _accepts_text_input(control) -> bool:
    if control is None:
        return False

    try:
        if not control.IsKeyboardFocusable:
            return False
    except Exception:
        return False

    control_type = control.ControlTypeName
    if control_type not in TEXT_FIELD_TYPES:
        return False

    # Only the control that actually has keyboard focus counts.
    # Cursor-under-point and name-hint heuristics caused false keyboard popups.
    return control_type in {"EditControl", "ComboBoxControl", "DocumentControl"}


def pc_text_field_is_focused() -> bool:
    try:
        import uiautomation as auto

        focused = auto.GetFocusedControl()
        return _accepts_text_input(focused)
    except Exception:
        return False


def describe_focus_target() -> str:
    try:
        import uiautomation as auto

        focused = auto.GetFocusedControl()

        def fmt(control) -> str:
            if control is None:
                return "none"
            return (
                f"{control.ControlTypeName}"
                f" class={control.ClassName!r}"
                f" name={control.Name!r}"
                f" focusable={control.IsKeyboardFocusable}"
            )

        return f"focus={fmt(focused)} accepts={pc_text_field_is_focused()}"
    except Exception as exc:
        return f"error={exc}"
