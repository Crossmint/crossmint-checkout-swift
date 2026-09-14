#!/usr/bin/env python3
"""
Convert DocC archive JSON to MDX files for Mintlify.

Usage:
    python3 docc-to-markdown.py <doccarchive-path>... --output <output-dir>

Example:
    python3 docc-to-markdown.py ./CrossmintCheckout.doccarchive --output sdk-reference/checkout/swift
    python3 docc-to-markdown.py ./CrossmintCheckout.doccarchive --output sdk-reference/checkout/swift --validate
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

# Maps DocC roleHeading values to output folders. Folder names must stay in sync
# with the docs.json navigation in crossbit-main (sdk-reference/checkout/swift/...).
ROLE_FOLDERS = {
    "Class": "classes",
    "Structure": "structs",
    "Enumeration": "enums",
    "Protocol": "protocols",
    "Type Alias": "type-aliases",
    "Function": "functions",
    "Operator": "functions",
    "Extended Module": "extensions",
}


def sanitize_filename(name: str) -> str:
    """Sanitize a filename: colons and parens cause issues on Windows and in URLs."""
    result = name.replace("(", "-").replace(":", "-").replace(")", "")
    result = re.sub(r"-+", "-", result)
    return result.strip("-")


def escape_mdx_text(text: str) -> str:
    """Escape < and > in plain text so MDX doesn't interpret them as JSX/HTML tags."""
    return text.replace("<", "\\<").replace(">", "\\>")


def escape_mdx_heading(text: str) -> str:
    """Escape <, >, and _ in symbol names used as headings.

    Swift operator names like <(_:_:) would be misinterpreted by the MDX parser
    as an HTML/JSX tag, causing a parse failure that blocks all link checking.
    Underscores also need escaping to avoid emphasis parsing in heading context.
    """
    return text.replace("<", "\\<").replace(">", "\\>").replace("_", "\\_")


def code_cell(text: str) -> str:
    """Format a value as an inline-code table cell. Backticks keep generics like
    Array\\<String\\> from being parsed as JSX; pipes are escaped so they don't
    end the cell."""
    text = text.strip().replace("|", "\\|")
    return f"`{text}`" if text else ""


def text_cell(text: str) -> str:
    """Flatten prose to a single-line table cell (descriptions may span lines)."""
    return text.strip().replace("\n", " ").replace("|", "\\|")


def extract_property_type(declaration: str) -> str:
    """Extract the type from a stored-property declaration.

    e.g. 'var address: String { get }' -> 'String'
         'let tokens: [CryptoCurrency] = []' -> '[CryptoCurrency]'
    """
    decl = declaration.strip()
    for cut in ("{", "="):
        index = decl.find(cut)
        if index != -1:
            decl = decl[:index]
    colon = decl.find(":")
    if colon == -1:
        return ""
    return decl[colon + 1:].strip()


PROPERTY_SECTIONS = {"Instance Properties", "Type Properties"}


def find_mintlify_root(path: Path) -> Path | None:
    """Walk up from path to find the Mintlify src root (directory containing docs.json)."""
    current = path.resolve()
    while current != current.parent:
        if (current / "docs.json").exists():
            return current
        current = current.parent
    return None


def render_inline_content(content: list, references: dict | None = None) -> str:
    """Render inline content elements to markdown."""
    if not content:
        return ""

    parts = []
    for item in content:
        item_type = item.get("type", "")

        if item_type == "text":
            parts.append(escape_mdx_text(item.get("text", "")))
        elif item_type == "codeVoice":
            parts.append(f"`{item.get('code', '')}`")
        elif item_type == "emphasis":
            inner = render_inline_content(item.get("inlineContent", []), references)
            parts.append(f"*{inner}*")
        elif item_type == "strong":
            inner = render_inline_content(item.get("inlineContent", []), references)
            parts.append(f"**{inner}**")
        elif item_type == "reference":
            identifier = item.get("identifier", "")
            symbol = identifier.split("/")[-1] if "/" in identifier else identifier
            if references:
                ref = references.get(identifier, {})
                title = ref.get("title", symbol)
                # Use backtick code for references in MDX
                parts.append(f"`{title}`")
            else:
                parts.append(f"`{symbol}`")
        elif item_type == "inlineHead":
            inner = render_inline_content(item.get("inlineContent", []), references)
            parts.append(f"**{inner}**")

    return "".join(parts)


def render_content(content: list, indent: int = 0, base_heading_level: int = 2, references: dict | None = None) -> str:
    """Render content sections to markdown."""
    if not content:
        return ""

    result = []
    indent_str = "  " * indent

    for item in content:
        item_type = item.get("type", "")

        if item_type == "paragraph":
            text = render_inline_content(item.get("inlineContent", []), references)
            result.append(f"{indent_str}{text}\n")

        elif item_type == "heading":
            level = item.get("level", 2)
            adjusted_level = base_heading_level + (level - 2)
            text = render_inline_content(item.get("inlineContent", []), references)
            if text.strip():
                result.append(f"\n{'#' * adjusted_level} {text}\n")

        elif item_type == "codeListing":
            code = "\n".join(item.get("code", []))
            lang = item.get("syntax", "swift")
            result.append(f"\n```{lang}\n{code}\n```\n")

        elif item_type == "unorderedList":
            for list_item in item.get("items", []):
                item_content = render_content(list_item.get("content", []), indent, base_heading_level, references)
                result.append(f"{indent_str}- {item_content.strip()}\n")

        elif item_type == "orderedList":
            for i, list_item in enumerate(item.get("items", []), 1):
                item_content = render_content(list_item.get("content", []), indent, base_heading_level, references)
                result.append(f"{indent_str}{i}. {item_content.strip()}\n")

        elif item_type == "aside":
            style = item.get("style", "note")
            inner = render_content(item.get("content", []), 0, base_heading_level, references)
            # Use Mintlify callout format
            callout_type = "info" if style == "important" else style
            result.append(f"\n> **{callout_type.capitalize()}**: {inner.strip()}\n")

        elif item_type == "termList":
            for term_item in item.get("items", []):
                term = render_inline_content(term_item.get("term", {}).get("inlineContent", []), references)
                definition = render_content(term_item.get("definition", {}).get("content", []), 0, base_heading_level, references)
                result.append(f"\n**{term}**: {definition.strip()}\n")

    return "".join(result)


def load_json_file(json_path: Path) -> dict | None:
    """Load and parse a JSON file."""
    try:
        with open(json_path) as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError):
        return None


def load_child_symbol(identifier: str, parent_dir: Path) -> dict | None:
    """Load the DocC JSON for a child symbol referenced by a topic section."""
    symbol = identifier.split("/")[-1] if "/" in identifier else identifier
    child_json = parent_dir / f"{symbol.lower()}.json"
    if child_json.exists():
        return load_json_file(child_json)
    return None


def get_declaration(data: dict) -> str:
    """Concatenate a symbol's declaration tokens into one string."""
    for section in data.get("primaryContentSections", []):
        if section.get("kind") == "declarations":
            for decl in section.get("declarations", []):
                return "".join(t.get("text", "") for t in decl.get("tokens", []))
    return ""


def render_parameters_table(params: list, references: dict, heading: str) -> str:
    """Render a parameter list as a table. Types stay in the signature block above,
    so this table pairs each parameter name with its description."""
    lines = [f"\n{heading} Parameters\n"]
    lines.append("\n| Parameter | Description |\n| ------ | ------ |\n")
    for param in params:
        name = param.get("name", "")
        desc = render_content(param.get("content", []), references=references)
        lines.append(f"| {code_cell(name)} | {text_cell(desc)} |\n")
    return "".join(lines)


def render_child_symbol(data: dict, heading_level: int = 3) -> str:
    """Render a child symbol (method, property) as markdown section."""
    metadata = data.get("metadata", {})
    title = metadata.get("title", "")
    references = data.get("references", {})

    if not title:
        return ""

    md = []

    md.append(f"\n{'#' * heading_level} {escape_mdx_heading(title)}\n")

    # Abstract
    abstract = render_inline_content(data.get("abstract", []), references)
    if abstract:
        md.append(f"\n{abstract}\n")

    # Declaration
    for section in data.get("primaryContentSections", []):
        if section.get("kind") == "declarations":
            for decl in section.get("declarations", []):
                tokens = decl.get("tokens", [])
                declaration = "".join(t.get("text", "") for t in tokens)
                if declaration:
                    md.append(f"\n```swift\n{declaration}\n```\n")
                break

    # Discussion/Content
    for section in data.get("primaryContentSections", []):
        if section.get("kind") == "content":
            content = render_content(section.get("content", []), references=references)
            if content.strip():
                md.append(f"\n{content}")

    # Parameters
    for section in data.get("primaryContentSections", []):
        if section.get("kind") == "parameters":
            params = section.get("parameters", [])
            if params:
                md.append(render_parameters_table(params, references, "#" * (heading_level + 1)))

    return "".join(md)


def json_to_mdx(json_path: Path, data: dict) -> str | None:
    """Convert a loaded DocC JSON document to MDX, including child symbols inline."""
    metadata = data.get("metadata", {})
    title = metadata.get("title", "")
    role_heading = metadata.get("roleHeading", "")

    if not title:
        return None

    references = data.get("references", {})

    md = []

    # MDX frontmatter
    md.append("---\n")
    md.append(f"title: \"{title}\"\n")
    if role_heading:
        md.append(f"description: \"Swift {role_heading}\"\n")
    md.append("---\n\n")

    # Role heading (e.g., "Class", "Protocol", "Structure")
    if role_heading:
        md.append(f"\n**{role_heading}**\n")

    # Abstract
    abstract = render_inline_content(data.get("abstract", []), references)
    if abstract:
        md.append(f"\n{abstract}\n")

    # Declaration
    for section in data.get("primaryContentSections", []):
        if section.get("kind") == "declarations":
            for decl in section.get("declarations", []):
                tokens = decl.get("tokens", [])
                declaration = "".join(t.get("text", "") for t in tokens)
                if declaration:
                    md.append(f"\n```swift\n{declaration}\n```\n")
                break

    # Discussion/Content
    for section in data.get("primaryContentSections", []):
        if section.get("kind") == "content":
            content = render_content(section.get("content", []), references=references)
            if content.strip():
                md.append(f"\n{content}")

    # Parameters (for top-level, e.g., functions)
    for section in data.get("primaryContentSections", []):
        if section.get("kind") == "parameters":
            params = section.get("parameters", [])
            if params:
                md.append(render_parameters_table(params, references, "##"))

    # Topics with inline children - skip Default Implementations
    topic_sections = data.get("topicSections", [])
    filtered_topics = [
        section for section in topic_sections
        if section.get("title", "") not in ("Default Implementations",)
    ]

    # Get the directory where child JSON files would be
    parent_dir = json_path.parent / json_path.stem

    for section in filtered_topics:
        section_title = section.get("title", "")
        identifiers = section.get("identifiers", [])
        if not section_title or not identifiers:
            continue

        # Property and enum-case sections render as a scannable summary table
        # rather than one code block per member (mirrors the TypeScript docs).
        # Each branch emits its heading only once it has content, so a section
        # whose child symbols all fail to load doesn't leave an orphaned heading.
        if section_title in PROPERTY_SECTIONS:
            rows = []
            for identifier in identifiers:
                child_data = load_child_symbol(identifier, parent_dir)
                if child_data:
                    name = child_data.get("metadata", {}).get("title", "")
                    prop_type = extract_property_type(get_declaration(child_data))
                    desc = render_inline_content(child_data.get("abstract", []), child_data.get("references", {}))
                else:
                    ref = references.get(identifier, {})
                    name = ref.get("title", identifier.split("/")[-1])
                    prop_type = ""
                    desc = ""
                rows.append((name, prop_type, desc))
            if rows:
                md.append(f"\n## {section_title}\n")
                md.append("\n| Property | Type | Description |\n| ------ | ------ | ------ |\n")
                for name, prop_type, desc in rows:
                    md.append(f"| {code_cell(name)} | {code_cell(prop_type)} | {text_cell(desc) or '-'} |\n")
            continue

        if section_title == "Enumeration Cases":
            rows = []
            for identifier in identifiers:
                child_data = load_child_symbol(identifier, parent_dir)
                if child_data:
                    name = child_data.get("metadata", {}).get("title", "")
                    desc = render_inline_content(child_data.get("abstract", []), child_data.get("references", {}))
                else:
                    ref = references.get(identifier, {})
                    name = ref.get("title", identifier.split("/")[-1])
                    desc = ""
                rows.append((name.removeprefix(f"{title}."), desc))
            if rows:
                md.append(f"\n## {section_title}\n")
                md.append("\n| Case | Description |\n| ------ | ------ |\n")
                for name, desc in rows:
                    md.append(f"| {code_cell(name)} | {text_cell(desc) or '-'} |\n")
            continue

        md.append(f"\n## {section_title}\n")
        for identifier in identifiers:
            # Extract symbol name from identifier
            symbol = identifier.split("/")[-1] if "/" in identifier else identifier
            symbol_lower = symbol.lower()

            # Try to find the child JSON file
            child_json = parent_dir / f"{symbol_lower}.json"

            if child_json.exists():
                child_data = load_json_file(child_json)
                if child_data:
                    child_md = render_child_symbol(child_data, heading_level=3)
                    if child_md:
                        md.append(child_md)
                    continue

            ref = references.get(identifier, {})
            ref_title = ref.get("title", symbol)
            md.append(f"\n### {escape_mdx_heading(ref_title)}\n")

    return "".join(md)


def is_top_level_symbol(json_path: Path, data_path: Path) -> bool:
    """Check if a JSON file represents a top-level symbol (not a child)."""
    rel_path = json_path.relative_to(data_path)
    parts = rel_path.parts

    # Module-level JSON files (e.g., crossmintcheckout.json)
    if len(parts) == 1:
        return False  # Skip module index files

    # Top-level symbols are directly under the module directory
    # e.g., crossmintcheckout/checkoutorder.json (2 parts)
    # Child symbols are deeper: crossmintcheckout/checkoutorder/orderid.json (3+ parts)
    if len(parts) == 2:
        return True

    return False


def generate_mdx_files(
    archive_path: Path,
    output_dir: Path,
    modules: list[str] | None = None,
    written: dict[Path, Path] | None = None
) -> int:
    """Generate MDX files for top-level symbols with children inline."""
    data_path = archive_path / "data" / "documentation"

    if not data_path.exists():
        raise FileNotFoundError(f"Documentation data not found in {archive_path}")

    output_dir.mkdir(parents=True, exist_ok=True)

    count = 0
    if written is None:
        written = {}

    # Sorted so collisions resolve the same way regardless of filesystem order.
    for json_file in sorted(data_path.rglob("*.json")):
        # Get relative path from data/documentation
        rel_path = json_file.relative_to(data_path)

        # Filter by modules if specified
        if modules:
            top_level_module = rel_path.parts[0] if rel_path.parts else ""
            if top_level_module.endswith(".json"):
                top_level_module = top_level_module[:-5]
            if top_level_module not in modules:
                continue

        # Only process top-level symbols
        if not is_top_level_symbol(json_file, data_path):
            continue

        data = load_json_file(json_file)
        if not data:
            continue

        # Convert to MDX with children inline
        mdx_content = json_to_mdx(json_file, data)
        if not mdx_content:
            continue

        role_heading = data.get("metadata", {}).get("roleHeading", "")
        folder = ROLE_FOLDERS.get(role_heading)
        if folder is None:
            print(f"Warning: skipping {rel_path}: unmapped role heading '{role_heading}'", file=sys.stderr)
            continue

        safe_stem = sanitize_filename(json_file.stem)
        output_path = output_dir / folder / f"{safe_stem}.mdx"
        if output_path in written:
            print(
                f"Warning: {folder}/{safe_stem}.mdx generated by both {written[output_path]} and {rel_path}"
                " — the latter wins; rename one of the symbols or scope the modules",
                file=sys.stderr,
            )
        written[output_path] = rel_path
        output_path.parent.mkdir(parents=True, exist_ok=True)

        output_path.write_text(mdx_content)
        count += 1

    return count


def main():
    parser = argparse.ArgumentParser(
        description="Convert DocC archive to MDX files for Mintlify"
    )
    parser.add_argument(
        "archives",
        type=Path,
        nargs="+",
        help="Paths to .doccarchive directories (one per module)"
    )
    parser.add_argument(
        "--output", "-o",
        type=Path,
        required=True,
        help="Output directory for MDX files"
    )
    parser.add_argument(
        "--modules", "-m",
        nargs="+",
        help="Only generate docs for specified modules (e.g., crossmintcheckout)"
    )
    parser.add_argument(
        "--validate",
        action="store_true",
        help="Run 'mint validate' and 'mint broken-links' after generation"
    )

    args = parser.parse_args()

    missing = [archive for archive in args.archives if not archive.exists()]
    if missing:
        for archive in missing:
            print(f"Error: Archive not found: {archive}", file=sys.stderr)
        sys.exit(1)

    count = 0
    written: dict[Path, Path] = {}
    for archive in args.archives:
        count += generate_mdx_files(
            archive,
            args.output,
            modules=args.modules,
            written=written
        )
    print(f"Generated {count} .mdx files in {args.output}")

    if args.validate:
        mintlify_root = find_mintlify_root(args.output)
        if not mintlify_root:
            print("Warning: Could not find Mintlify root (docs.json) — skipping validation.", file=sys.stderr)
            sys.exit(1)
        print(f"\nRunning mint validate in {mintlify_root}...")
        result = subprocess.run(["mint", "validate"], cwd=mintlify_root)
        if result.returncode != 0:
            sys.exit(result.returncode)
        print("\nRunning mint broken-links...")
        result = subprocess.run(["mint", "broken-links"], cwd=mintlify_root)
        if result.returncode != 0:
            sys.exit(result.returncode)


if __name__ == "__main__":
    main()
