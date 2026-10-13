#!/usr/bin/env python3
import re
import sys
from dataclasses import dataclass


INDENT = 4


@dataclass
class Call:
    name: str
    args: str


@dataclass
class Node:
    plus: bool
    call: Call
    parts: list


def skip_ws(src, pos):
    while pos < len(src) and src[pos].isspace():
        pos += 1
    return pos


def matching(src, pos, opener, closer):
    depth = 0
    quote = None
    escape = False
    line_comment = False
    block_comment = False
    i = pos

    while i < len(src):
        ch = src[i]
        nxt = src[i + 1] if i + 1 < len(src) else ""

        if line_comment:
            if ch == "\n":
                line_comment = False
            i += 1
            continue

        if block_comment:
            if ch == "*" and nxt == "/":
                block_comment = False
                i += 2
            else:
                i += 1
            continue

        if quote:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == quote:
                quote = None
            i += 1
            continue

        if ch == "/" and nxt == "/":
            line_comment = True
            i += 2
            continue
        if ch == "/" and nxt == "*":
            block_comment = True
            i += 2
            continue
        if ch in ("'", '"'):
            quote = ch
            i += 1
            continue
        if ch == opener:
            depth += 1
        elif ch == closer:
            depth -= 1
            if depth == 0:
                return i
        i += 1

    return None


def statement_end(src, pos):
    paren = bracket = brace = 0
    quote = None
    escape = False
    line_comment = False
    block_comment = False
    i = pos

    while i < len(src):
        ch = src[i]
        nxt = src[i + 1] if i + 1 < len(src) else ""

        if line_comment:
            if ch == "\n":
                line_comment = False
            i += 1
            continue

        if block_comment:
            if ch == "*" and nxt == "/":
                block_comment = False
                i += 2
            else:
                i += 1
            continue

        if quote:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == quote:
                quote = None
            i += 1
            continue

        if ch == "/" and nxt == "/":
            line_comment = True
            i += 2
            continue
        if ch == "/" and nxt == "*":
            block_comment = True
            i += 2
            continue
        if ch in ("'", '"'):
            quote = ch
        elif ch == "(":
            paren += 1
        elif ch == ")":
            paren -= 1
        elif ch == "[":
            bracket += 1
        elif ch == "]":
            bracket -= 1
        elif ch == "{":
            brace += 1
        elif ch == "}":
            brace -= 1
        elif ch == ";" and paren == 0 and bracket == 0 and brace == 0:
            return i
        i += 1

    return None


def has_code_brace(src):
    quote = None
    escape = False
    line_comment = False
    block_comment = False
    i = 0

    while i < len(src):
        ch = src[i]
        nxt = src[i + 1] if i + 1 < len(src) else ""

        if line_comment:
            if ch == "\n":
                line_comment = False
            i += 1
            continue

        if block_comment:
            if ch == "*" and nxt == "/":
                block_comment = False
                i += 2
            else:
                i += 1
            continue

        if quote:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == quote:
                quote = None
            i += 1
            continue

        if ch == "/" and nxt == "/":
            line_comment = True
            i += 2
            continue
        if ch == "/" and nxt == "*":
            block_comment = True
            i += 2
            continue
        if ch in ("'", '"'):
            quote = ch
        elif ch in "{}":
            return True
        i += 1

    return False


def compact(src):
    out = []
    quote = None
    escape = False
    pending_space = False

    for ch in src.strip():
        if quote:
            out.append(ch)
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == quote:
                quote = None
            continue

        if ch in ("'", '"'):
            if pending_space and out:
                out.append(" ")
            pending_space = False
            quote = ch
            out.append(ch)
        elif ch.isspace():
            pending_space = True
        else:
            if pending_space and out and out[-1] not in "([<":
                out.append(" ")
            pending_space = False
            out.append(ch)

    return "".join(out).strip()


def split_args(src):
    args = []
    start = 0
    paren = bracket = brace = 0
    quote = None
    escape = False
    i = 0

    while i < len(src):
        ch = src[i]
        if quote:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == quote:
                quote = None
        elif ch in ("'", '"'):
            quote = ch
        elif ch == "(":
            paren += 1
        elif ch == ")":
            paren -= 1
        elif ch == "[":
            bracket += 1
        elif ch == "]":
            bracket -= 1
        elif ch == "{":
            brace += 1
        elif ch == "}":
            brace -= 1
        elif ch == "," and paren == 0 and bracket == 0 and brace == 0:
            args.append(src[start:i].strip())
            start = i + 1
        i += 1

    tail = src[start:].strip()
    if tail:
        args.append(tail)
    return args


class Parser:
    def __init__(self, src):
        self.src = src

    def parse_node(self, pos):
        src = self.src
        pos = skip_ws(src, pos)
        plus = False
        if pos < len(src) and src[pos] == "+":
            plus = True
            pos = skip_ws(src, pos + 1)

        call, pos = self.parse_call(pos)
        if call is None:
            return None, pos

        parts = []
        while True:
            pos = skip_ws(src, pos)
            if pos >= len(src):
                break
            if src[pos] == ".":
                chain, pos = self.parse_call(pos)
                if chain is None:
                    return None, pos
                parts.append(("chain", chain))
                continue
            if src[pos] == "[":
                end = matching(src, pos, "[", "]")
                if end is None:
                    return None, pos
                children = parse_children(src[pos + 1 : end])
                if children is None:
                    return None, pos
                parts.append(("children", children))
                pos = end + 1
                continue
            break

        return Node(plus, call, parts), pos

    def parse_call(self, pos):
        src = self.src
        start = pos
        paren = src.find("(", pos)
        if paren == -1:
            return None, pos

        name = compact(src[start:paren])
        if not re.fullmatch(r"\.?[A-Za-z_][A-Za-z_0-9:<>~]*", name):
            return None, pos

        end = matching(src, paren, "(", ")")
        if end is None:
            return None, pos

        return Call(name, src[paren + 1 : end]), end + 1


def parse_children(src):
    parser = Parser(src)
    children = []
    pos = 0

    while True:
        pos = skip_ws(src, pos)
        if pos >= len(src):
            break
        node, pos = parser.parse_node(pos)
        if node is None:
            return None
        children.append(node)
        pos = skip_ws(src, pos)
        if pos < len(src) and src[pos] == "+":
            continue
        if pos < len(src):
            return None

    return children


def has_children(node):
    for kind, value in node.parts:
        if kind == "children":
            return True
        if kind == "chain":
            continue
        for child in value:
            if has_children(child):
                return True
    return False


def format_call(call, indent, plus=False):
    prefix = " " * indent + ("+" if plus else "")
    args = split_args(call.args)

    if len(args) <= 1:
        arg_text = compact(args[0]) if args else ""
        return [f"{prefix}{call.name}({arg_text})"]

    lines = [f"{prefix}{call.name}("]
    for index, arg in enumerate(args):
        comma = "," if index < len(args) - 1 else ""
        lines.append(f"{' ' * (indent + INDENT)}{compact(arg)}{comma}")
    lines.append(f"{' ' * indent})")
    return lines


def format_node(node, indent):
    lines = format_call(node.call, indent, node.plus)

    for kind, value in node.parts:
        if kind == "chain":
            lines.extend(format_call(value, indent + INDENT))
        else:
            lines.append(" " * (indent + INDENT) + "[")
            for child in value:
                lines.extend(format_node(child, indent + (INDENT * 2)))
            lines.append(" " * (indent + INDENT) + "]")

    return lines


def line_indent(src, pos):
    line_start = src.rfind("\n", 0, pos) + 1
    indent = 0
    while line_start + indent < len(src) and src[line_start + indent] == " ":
        indent += 1
    return indent


def format_text(src):
    replacements = []
    pos = 0
    pattern = re.compile(r"\bUI::[A-Za-z_][A-Za-z_0-9]*\s*\(")

    while True:
        match = pattern.search(src, pos)
        if not match:
            break

        end = statement_end(src, match.start())
        if end is None:
            pos = match.end()
            continue

        expr = src[match.start() : end]
        if has_code_brace(expr):
            pos = end + 1
            continue

        parser = Parser(src)
        node, parsed_end = parser.parse_node(match.start())
        parsed_end = skip_ws(src, parsed_end)
        if node is None or parsed_end != end or not has_children(node):
            pos = match.end()
            continue

        indent = line_indent(src, match.start())
        formatted = format_node(node, indent)
        if formatted and formatted[0].startswith(" " * indent):
            formatted[0] = formatted[0][indent:]
        replacement = "\n".join(formatted)
        replacements.append((match.start(), end, replacement))
        pos = end + 1

    for start, end, replacement in reversed(replacements):
        src = src[:start] + replacement + src[end:]
    return src


def main():
    original = sys.stdin.read()
    try:
        sys.stdout.write(format_text(original))
    except Exception:
        sys.stdout.write(original)


if __name__ == "__main__":
    main()
