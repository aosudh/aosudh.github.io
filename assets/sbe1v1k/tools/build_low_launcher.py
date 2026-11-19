#!/usr/bin/env python3
"""Build the exact audited low-address FIT launcher from a pinned local input.

Standalone Python standard library only. No download, router access or execution.
Writes only the explicitly requested ordinary local output file.
"""
import argparse
import hashlib
import json
from pathlib import Path
import stat
import struct
import sys

SOURCE_SIZE = 859
SOURCE_SHA256 = '498bc402dc720bd7cd93ffc400fbbd308d64785e950a8a5bc54ae72896a09bba'
TARGET_SIZE = 863
TARGET_SHA256 = '999775118abefc7c8b798ff85f8bf1826ce84c94e777b8582cfea983d3776125'
SCRIPT = b'setenv serverip 172.16.252.252; tftpboot 0x44000000 initramfs.itb && bootm 0x44000000\n'
SCRIPT_NODE = '/images/script'
HASH_NODE = SCRIPT_NODE + '/hash-1'


class AuditError(Exception):
    pass


def require(condition, message):
    if not condition:
        raise AuditError(message)


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def local_path(value):
    normalized = str(value).replace('\\', '/')
    require(not normalized.startswith('//'), 'UNC and Windows device paths are refused')
    require(not normalized.startswith('/dev/'), 'Device paths are refused')
    return Path(value)


def parse_fdt(data):
    """Return properties, property spans and header, rejecting malformed FDT."""
    require(len(data) >= 40, 'Truncated FDT header')
    header = list(struct.unpack_from('>10I', data))
    magic, total, start, string_start, reserve, version, compatible, _, string_size, structure_size = header
    end = start + structure_size
    string_end = string_start + string_size
    require(magic == 0xd00dfeed and total == len(data), 'Invalid FDT magic or length')
    require(version == 17 and compatible <= 17, 'Unsupported FDT version')
    require(start % 4 == 0 and reserve % 8 == 0, 'Misaligned FDT block')
    require(40 <= start < end == string_start < string_end <= total, 'Unexpected FDT block layout')
    require(not any(data[string_end:]), 'Unexpected nonzero FDT trailing padding')
    require(40 <= reserve < start, 'Invalid reservation map offset')
    position = reserve
    while True:
        require(position + 16 <= start, 'Unterminated reservation map')
        address, size = struct.unpack_from('>QQ', data, position)
        position += 16
        if address == size == 0:
            break
    strings = data[string_start:string_end]
    nodes, spans, stack = {}, {}, []
    position = start
    finished = False
    while position < end:
        require(position + 4 <= end, 'Truncated FDT token')
        token_start = position
        token = struct.unpack_from('>I', data, position)[0]
        position += 4
        if token == 1:
            stop = data.find(b'\0', position, end)
            require(stop >= 0, 'Unterminated node name')
            name = data[position:stop].decode('ascii')
            require('/' not in name and (stack or name == ''), 'Invalid root or node name')
            require(not stack or bool(name), 'Empty child name')
            stack.append(name)
            node = '/' + '/'.join(x for x in stack if x)
            require(node not in nodes, 'Duplicate FDT node')
            nodes[node] = {}
            position = (stop + 4) & ~3
            require(position <= end, 'Node extends beyond structure')
        elif token == 2:
            require(bool(stack), 'Unbalanced node end')
            stack.pop()
        elif token == 3:
            require(bool(stack) and position + 8 <= end, 'Invalid property header')
            length, name_offset = struct.unpack_from('>II', data, position)
            position += 8
            require(position + length <= end and name_offset < len(strings), 'Property outside FDT bounds')
            stop = strings.find(b'\0', name_offset)
            require(stop >= 0, 'Unterminated property name')
            name = strings[name_offset:stop].decode('ascii')
            node = '/' + '/'.join(x for x in stack if x)
            require(bool(name) and name not in nodes[node], 'Empty or duplicate property')
            nodes[node][name] = data[position:position + length]
            position = (position + length + 3) & ~3
            require(position <= end, 'Property padding outside FDT')
            spans[node, name] = (token_start, position, name_offset)
        elif token == 4:
            continue
        elif token == 9:
            require(not stack and '/' in nodes and position == end, 'Invalid FDT end')
            finished = True
            break
        else:
            raise AuditError('Unknown FDT token')
    require(finished, 'Missing FDT_END')
    return nodes, spans, header


def verify_hashes(nodes):
    images = {p for p in nodes if p.startswith('/images/') and p.count('/') == 2}
    require(images == {'/images/RTQ7300T', SCRIPT_NODE}, 'Unexpected FIT image set')
    verified = []
    for image in sorted(images):
        props = nodes[image]
        require('data' in props and props.get('compression') == b'none\0', 'Unsupported FIT image data')
        children = {p for p in nodes if p.startswith(image + '/')}
        require(children == {image + '/hash-1'}, 'Unexpected or missing FIT hash node')
        entry = nodes[image + '/hash-1']
        require(set(entry) == {'value', 'algo'} and entry['algo'] == b'sha256\0', 'Unsupported FIT hash')
        require(hashlib.sha256(props['data']).digest() == entry['value'], 'Embedded FIT SHA256 mismatch')
        verified.append({'node': image + '/hash-1', 'algorithm': 'sha256', 'valid': True})
    require(nodes[SCRIPT_NODE].get('type') == b'script\0', 'Expected script type missing')
    return verified


def rebuild(data, spans, header, replacements):
    pieces = []
    cursor = header[2]
    for key, payload in sorted(replacements.items(), key=lambda item: spans[item[0]][0]):
        first, last, name_offset = spans[key]
        require(cursor <= first < last, 'Overlapping replacement properties')
        pieces.append(data[cursor:first])
        pieces.append(struct.pack('>III', 3, len(payload), name_offset) + payload + bytes((-len(payload)) % 4))
        cursor = last
    pieces.append(data[cursor:header[2] + header[9]])
    structure = b''.join(pieces)
    prefix = bytearray(data[:header[2]])
    suffix = data[header[3]:]
    updated_header = list(header)
    updated_header[1] = len(prefix) + len(structure) + len(suffix)
    updated_header[3] = len(prefix) + len(structure)
    updated_header[9] = len(structure)
    prefix[:40] = struct.pack('>10I', *updated_header)
    return bytes(prefix) + structure + suffix


def build(input_value, output_value):
    source, output = local_path(input_value), local_path(output_value)
    require(not source.is_symlink() and not output.is_symlink(), 'Symlink input or output refused')
    require(source.resolve() != output.resolve(), 'Refusing to replace the original input')
    info = source.stat()
    require(stat.S_ISREG(info.st_mode), 'Input must be an ordinary file')
    require(info.st_size == SOURCE_SIZE, 'Input size must match the pinned 859-byte FIT')
    with source.open('rb') as stream:
        data = stream.read(SOURCE_SIZE + 1)
    require(len(data) == SOURCE_SIZE and sha256(data) == SOURCE_SHA256, 'Original launcher SHA256 mismatch')
    nodes, spans, header = parse_fdt(data)
    verify_hashes(nodes)
    require(rebuild(data, spans, header, {}) == data, 'Original FIT roundtrip mismatch')
    replacements = {(SCRIPT_NODE, 'data'): SCRIPT, (HASH_NODE, 'value'): hashlib.sha256(SCRIPT).digest()}
    updated = rebuild(data, spans, header, replacements)
    after, after_spans, after_header = parse_fdt(updated)
    expected = {node: dict(props) for node, props in nodes.items()}
    for (node, name), value in replacements.items():
        expected[node][name] = value
    require(after == expected, 'Non-script FIT properties changed')
    require(rebuild(updated, after_spans, after_header, {}) == updated, 'Output FIT roundtrip mismatch')
    checks = verify_hashes(after)
    require(len(updated) == TARGET_SIZE and sha256(updated) == TARGET_SHA256, 'Output differs from the pinned audited result')
    created = False
    if output.exists():
        require(stat.S_ISREG(output.stat().st_mode), 'Output must be an ordinary file')
        require(output.stat().st_size == TARGET_SIZE and output.read_bytes() == updated, 'Refusing to overwrite different existing output')
    else:
        require(output.parent.is_dir(), 'Output parent directory must already exist')
        with output.open('xb') as stream:
            require(stream.write(updated) == len(updated), 'Short output write')
            stream.flush()
        created = True
    require(output.read_bytes() == updated, 'Output file readback mismatch')
    return {'ok': True, 'input_bytes': SOURCE_SIZE, 'input_sha256': SOURCE_SHA256,
            'output_bytes': len(updated), 'output_sha256': TARGET_SHA256,
            'script': SCRIPT.decode('ascii'), 'embedded_hashes': checks,
            'non_script_properties_unchanged': True, 'single_physical_line': True,
            'output_created': created, 'persistent_write_commands_in_script': False,
            'router_contacted': False, 'firmware_executed': False, 'raw_disks_written': False}


def main(argv=None):
    parser = argparse.ArgumentParser(prog='build_low_launcher.py', description=__doc__)
    parser.add_argument('input', help='Original 859-byte launcher file')
    parser.add_argument('output', help='New local 863-byte launcher file')
    args = parser.parse_args(argv)
    try:
        result = build(args.input, args.output)
    except AuditError as error:
        result = {'ok': False, 'error': str(error)}
    except (OSError, UnicodeError, struct.error, KeyError, ValueError):
        result = {'ok': False, 'error': 'Input parsing or local file operation failed'}
    print(json.dumps(result, indent=2))
    return 0 if result['ok'] else 1


if __name__ == '__main__':
    sys.exit(main())
