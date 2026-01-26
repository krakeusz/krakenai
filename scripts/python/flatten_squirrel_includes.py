import argparse
from pathlib import Path
import re
import sys
from typing import Sequence


def parse_args(argv: Sequence[str] | None = None):
    if argv is None:
        argv = sys.argv[1:]
        
    parser = argparse.ArgumentParser()
    parser.add_argument("src", type=Path, help="A path to the input squirrel source file.")
    parser.add_argument("--output", "-o", required=True, type=Path, help="A path of the output squirrel file to be created.")
    
    return parser.parse_args(argv)

INCLUDE_REGEX = re.compile(r'^\s*require\("([^/\\]*(/|\\))*([^/\\]+.nut)"\).*')

def process_source_line(line: str) -> str:
    match = INCLUDE_REGEX.match(line)
    if match:
        return f'require("{match[3]}")'
    return line

def process_source_file_contents(contents: str) -> str:
    output_lines = []
    for line in contents.splitlines():
        output_lines.append(process_source_line(line))
    return '\n'.join(output_lines)

def process_source_file(input_file: Path, output_file: Path) -> None:
    output_file.write_text(process_source_file_contents(input_file.read_text()))
    
def main():
    args = parse_args()
    process_source_file(args.src, args.output)

if __name__ == "__main__":
    main()