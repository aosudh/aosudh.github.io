#!/usr/bin/env python3
"""Offline, exact-artifact SBE1V1K audit/patch utility. Standard library only.

Reads ordinary local files. Writes only a new explicitly named ITB file.
Does not contact routers, execute firmware, or open raw disks/devices.
"""
import argparse
import hashlib
import io
import json
from pathlib import Path
import stat
import struct
import sys
import tarfile
import zlib

FIRMWARE_SIZE = 119685913
FIRMWARE_SHA256 = '0a033c708675c68e1765661ace2d6a03d902b35b1d62e88f1a4cae9fa8c7dd64'
LOADER_SIZE = 804036
LOADER_SHA256 = '6e83ca577933585e5140ee80a08d40bc75872bf08375c9b3d7ffeab23f431347'
PATCHED_SHA256 = '8a7b5911001dd34b0cedbeda000e7ac0f096599b7b1b0ef21c9c147f982a6359'
MEMBERS = {
    'kernel': (5772792, '1156eceaafaaa458ea0a7c3e2ea8616e1da7e1642aca109f6320f3dff4face78'),
    'root': (113901568, '7e41ac7e6948cef56090415899c5148d3607bba684b623e39a3f0e87b11df161'),
}
OLD = b'fstools_ignore_partname=1\0'
NEW = b'fstools_ignore_partname=0\0'


class AuditError(Exception):
    """A deliberately path-free error suitable for public logs."""


def require(condition, message):
    if not condition:
        raise AuditError(message)


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def local_path(value):
    raw = str(value)
    normalized = raw.replace('\\', '/')
    require(not normalized.startswith('//'), 'UNC and Windows device paths are refused')
    require(not normalized.startswith('/dev/'), 'Device paths are refused')
    return Path(value)


def read_exact_file(value, size, digest):
    path = local_path(value)
    require(not path.is_symlink(), 'Symlink inputs are refused')
    info = path.stat()
    require(stat.S_ISREG(info.st_mode), 'Input must be an ordinary file')
    require(info.st_size == size, 'Input size does not match the pinned artifact')
    with path.open('rb') as stream:
        data = stream.read(size + 1)
    require(len(data) == size, 'Input changed or has an unexpected size')
    require(sha256(data) == digest, 'Input SHA256 does not match the pinned artifact')
    return path, data


def inspect_firmware(value):
    _, data = read_exact_file(value, FIRMWARE_SIZE, FIRMWARE_SHA256)
    prefix = 'sysupgrade-spectrum_sbe1v1k'
    expected = {prefix, prefix + '/CONTROL', prefix + '/kernel', prefix + '/root'}
    report = {}
    with tarfile.open(fileobj=io.BytesIO(data), mode='r:') as archive:
        members = archive.getmembers()
        require(len(members) == 4, 'Unexpected tar member count')
        require({m.name for m in members} == expected, 'Unexpected or duplicate tar member names')
        for member in members:
            if member.name == prefix:
                require(member.isdir() and member.size == 0, 'Invalid tar directory member')
                continue
            require(member.isfile() and not member.issparse(), 'Non-regular or sparse tar member refused')
            name = member.name.rsplit('/', 1)[1]
            if name == 'CONTROL':
                require(member.size == 23, 'Unexpected CONTROL length')
                continue
            size, digest = MEMBERS[name]
            require(member.size == size, 'Unexpected payload size: ' + name)
            stream = archive.extractfile(member)
            require(stream is not None, 'Cannot read tar payload: ' + name)
            with stream:
                body = stream.read(size + 1)
            require(len(body) == size and sha256(body) == digest, 'Payload SHA256 mismatch: ' + name)
            report[name] = {'bytes': size, 'sha256': digest}
    return {'ok': True, 'operation': 'inspect-firmware', 'bytes': len(data),
            'sha256': sha256(data), 'tar_members': 4, 'payloads': report,
            'router_contacted': False, 'files_written': False}


def parse_fdt(data):
    """Parse an inline-data FIT/FDT with strict bounds and duplicate checks."""
    require(len(data) >= 40, 'Truncated FDT header')
    magic, total, off_struct, off_strings, off_reserve, version, compatible, _, n_strings, n_struct = struct.unpack_from('>10I', data)
    require(magic == 0xd00dfeed and total == len(data), 'Invalid FDT magic or total size')
    require(version == 17 and compatible <= 17, 'Unsupported FDT version')
    require(off_struct % 4 == 0 and off_reserve % 8 == 0, 'Misaligned FDT block')
    end_struct, end_strings = off_struct + n_struct, off_strings + n_strings
    require(40 <= off_struct < end_struct <= total, 'Invalid FDT structure bounds')
    require(40 <= off_strings < end_strings <= total, 'Invalid FDT strings bounds')
    require(end_struct <= off_strings or end_strings <= off_struct, 'Overlapping FDT blocks')
    require(40 <= off_reserve < min(off_struct, off_strings), 'Invalid FDT reservation map')
    reserve = off_reserve
    while True:
        require(reserve + 16 <= min(off_struct, off_strings), 'Unterminated reservation map')
        address, size = struct.unpack_from('>QQ', data, reserve)
        reserve += 16
        if address == 0 and size == 0:
            break

    strings = data[off_strings:end_strings]
    nodes, spans, stack = {}, {}, []
    pos = off_struct
    ended = False
    while pos < end_struct:
        require(pos + 4 <= end_struct, 'Truncated FDT token')
        token = struct.unpack_from('>I', data, pos)[0]
        pos += 4
        if token == 1:  # FDT_BEGIN_NODE
            stop = data.find(b'\0', pos, end_struct)
            require(stop >= 0, 'Unterminated FDT node name')
            name = data[pos:stop].decode('ascii')
            require('/' not in name and (stack or name == ''), 'Invalid FDT node name')
            require(not stack or name != '', 'Empty child node name')
            stack.append(name)
            path = '/' + '/'.join(x for x in stack if x)
            require(path not in nodes, 'Duplicate FDT node')
            nodes[path] = {}
            pos = (stop + 4) & ~3
            require(pos <= end_struct, 'Invalid FDT node padding')
        elif token == 2:  # FDT_END_NODE
            require(bool(stack), 'Unbalanced FDT node end')
            stack.pop()
        elif token == 3:  # FDT_PROP
            require(bool(stack) and pos + 8 <= end_struct, 'Invalid FDT property header')
            length, index = struct.unpack_from('>II', data, pos)
            pos += 8
            require(index < len(strings) and pos + length <= end_struct, 'Invalid FDT property bounds')
            stop = strings.find(b'\0', index)
            require(stop >= 0, 'Unterminated FDT property name')
            key = strings[index:stop].decode('ascii')
            require(bool(key), 'Empty FDT property name')
            path = '/' + '/'.join(x for x in stack if x)
            require(key not in nodes[path], 'Duplicate FDT property')
            nodes[path][key] = data[pos:pos + length]
            spans[path, key] = (pos, length)
            pos = (pos + length + 3) & ~3
            require(pos <= end_struct, 'Invalid FDT property padding')
        elif token == 4:  # FDT_NOP
            continue
        elif token == 9:  # FDT_END
            require(not stack and '/' in nodes, 'Unbalanced FDT end')
            require(not any(data[pos:end_struct]), 'Unexpected bytes after FDT_END')
            ended = True
            break
        else:
            raise AuditError('Unknown FDT token')
    require(ended, 'Missing FDT_END')
    return nodes, spans


def verify_fit_hashes(nodes):
    images = [p for p in nodes if p.startswith('/images/') and p.count('/') == 2]
    require(set(images) == {'/images/fdt-1', '/images/kernel-1', '/images/uboot-1'}, 'Unexpected FIT image set')
    checks = []
    for path in images:
        props = nodes[path]
        require('data' in props, 'External FIT data is not supported')
        hashes = [p for p in nodes if p.startswith(path + '/') and p.count('/') == 3]
        require(bool(hashes), 'FIT image has no hash')
        for child in hashes:
            entry = nodes[child]
            require(set(entry) == {'algo', 'value'}, 'Unexpected FIT hash properties')
            raw_algo = entry['algo']
            require(raw_algo in (b'sha1\0', b'sha256\0', b'crc32\0'), 'Unsupported FIT hash algorithm')
            algorithm = raw_algo[:-1].decode('ascii')
            body = props['data']
            digest = struct.pack('>I', zlib.crc32(body) & 0xffffffff) if algorithm == 'crc32' else hashlib.new(algorithm, body).digest()
            require(digest == entry['value'], 'Embedded FIT hash mismatch')
            checks.append({'node': child, 'algorithm': algorithm, 'valid': True})
    return checks


def patch_loader(input_value, output_value):
    source, data = read_exact_file(input_value, LOADER_SIZE, LOADER_SHA256)
    output = local_path(output_value)
    require(source.resolve() != output.resolve(), 'Refusing to replace the original input')
    require(not output.is_symlink(), 'Symlink output refused')
    nodes, spans = parse_fdt(data)
    verify_fit_hashes(nodes)
    image_node = '/images/uboot-1'
    hash_node = image_node + '/hash-1'
    payload = nodes[image_node]['data']
    require(nodes[image_node].get('compression') == b'none\0', 'Compressed U-Boot payload refused')
    require(data.count(OLD) == payload.count(OLD) == 1 and NEW not in payload, 'Unexpected boot-argument literal')
    require(nodes[hash_node].get('algo') == b'sha1\0', 'Expected U-Boot SHA1 node missing')
    patched_payload = payload.replace(OLD, NEW)
    byte_offset = spans[image_node, 'data'][0] + payload.index(OLD) + len(OLD) - 2
    hash_offset, hash_length = spans[hash_node, 'value']
    require(hash_length == 20 and data[byte_offset] == ord('1'), 'Invalid patch locations')
    patched = bytearray(data)
    patched[byte_offset] = ord('0')
    patched[hash_offset:hash_offset + 20] = hashlib.sha1(patched_payload).digest()
    patched = bytes(patched)
    changed = {i for i, (a, b) in enumerate(zip(data, patched)) if a != b}
    allowed = {byte_offset} | set(range(hash_offset, hash_offset + 20))
    require(len(changed) == 21 and changed == allowed, 'Unexpected changed-byte set')
    after, after_spans = parse_fdt(patched)
    require(spans == after_spans and nodes.keys() == after.keys(), 'FIT structure changed')
    changed_properties = set()
    for path, props in nodes.items():
        require(props.keys() == after[path].keys(), 'FIT property set changed')
        changed_properties.update((path, key) for key in props if props[key] != after[path][key])
    require(changed_properties == {(image_node, 'data'), (hash_node, 'value')}, 'Unexpected FIT property change')
    checks = verify_fit_hashes(after)
    require(len(patched) == LOADER_SIZE and sha256(patched) == PATCHED_SHA256, 'Final output differs from the pinned audited result')
    created = False
    if output.exists():
        require(stat.S_ISREG(output.stat().st_mode), 'Output must be an ordinary file')
        require(output.stat().st_size == len(patched) and output.read_bytes() == patched, 'Refusing to overwrite different existing output')
    else:
        require(output.parent.is_dir(), 'Output parent directory must already exist')
        with output.open('xb') as stream:
            require(stream.write(patched) == len(patched), 'Short output write')
            stream.flush()
        created = True
    require(output.read_bytes() == patched, 'Output readback mismatch')
    return {'ok': True, 'operation': 'patch-loader', 'input_sha256': LOADER_SHA256,
            'output_sha256': PATCHED_SHA256, 'bytes': len(patched), 'changed_bytes': len(changed),
            'changed_properties': sorted('/'.join(pair) for pair in changed_properties),
            'embedded_hashes': checks, 'output_created': created, 'router_contacted': False,
            'raw_disks_written': False, 'official_unmodified_release': False}


def main(argv=None):
    parser = argparse.ArgumentParser(prog='inspect_and_patch.py', description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    inspect = commands.add_parser('inspect-firmware', help='Verify the exact pinned QWRT tar and its payloads')
    inspect.add_argument('input')
    patch = commands.add_parser('patch-loader', help='Create only the exact audited custom-p29 ITB')
    patch.add_argument('input')
    patch.add_argument('output')
    args = parser.parse_args(argv)
    try:
        result = inspect_firmware(args.input) if args.command == 'inspect-firmware' else patch_loader(args.input, args.output)
    except AuditError as error:
        result = {'ok': False, 'error': str(error)}
    except (OSError, UnicodeError, tarfile.TarError, struct.error, KeyError, ValueError):
        # Never include OS exception paths or arbitrary data in public command logs.
        result = {'ok': False, 'error': 'Input parsing or local file operation failed'}
    print(json.dumps(result, indent=2))
    return 0 if result['ok'] else 1


if __name__ == '__main__':
    sys.exit(main())
