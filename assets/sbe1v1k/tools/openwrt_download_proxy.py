"""Temporary Windows loopback proxy for official OpenWrt HTTPS downloads.

Python standard library only. Start explicitly with:
    python openwrt_download_proxy.py

Supports absolute-URL GET/HEAD (including uclient-fetch) and CONNECT.
Only downloads.openwrt.org:443 is allowed. No state files are written.
Stops on Ctrl+C or after 20 minutes; SSH forwarding is stopped separately.
"""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import http.client
import select
import socket
import ssl
import threading
from urllib.parse import urlsplit

LISTEN_HOST = "127.0.0.1"
LISTEN_PORT = 18080
ALLOWED_HOST = "downloads.openwrt.org"
LIFETIME_SECONDS = 20 * 60
IO_TIMEOUT_SECONDS = 45


def absolute_target(request_target):
    """Return the official HTTPS request path, or reject the target."""
    if any(ord(char) < 33 or ord(char) == 127 for char in request_target):
        raise ValueError("Control characters or whitespace in target")
    try:
        target = urlsplit(request_target)
        valid = (
            target.scheme == "https"
            and target.hostname == ALLOWED_HOST
            and target.port in (None, 443)
            and target.username is None
            and target.password is None
            and not target.fragment
        )
    except ValueError:
        raise ValueError("Malformed HTTPS target") from None
    if not valid:
        raise ValueError("Only official OpenWrt HTTPS downloads are allowed")
    return (target.path or "/") + ("?" + target.query if target.query else "")


def connect_target(request_target):
    """CONNECT permits one exact authority, never a client-selected host."""
    if request_target.lower() != ALLOWED_HOST + ":443":
        raise ValueError("Only official OpenWrt HTTPS downloads are allowed")
    return ALLOWED_HOST, 443


class ProxyServer(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(self):
        self._active_sockets = set()
        self._socket_lock = threading.Lock()
        super().__init__((LISTEN_HOST, LISTEN_PORT), Handler)

    def track_socket(self, connection):
        with self._socket_lock:
            self._active_sockets.add(connection)

    def untrack_socket(self, connection):
        with self._socket_lock:
            self._active_sockets.discard(connection)

    def close_active_connections(self):
        with self._socket_lock:
            connections = tuple(self._active_sockets)
            self._active_sockets.clear()
        for connection in connections:
            try:
                connection.shutdown(socket.SHUT_RDWR)
            except OSError:
                pass
            connection.close()


class Handler(BaseHTTPRequestHandler):
    # Close each HTTP request instead of retaining connections or credentials.
    protocol_version = "HTTP/1.0"
    server_version = "OpenWrtDownloadProxy"
    sys_version = ""

    def setup(self):
        self.request.settimeout(IO_TIMEOUT_SECONDS)
        super().setup()
        self.server.track_socket(self.connection)

    def finish(self):
        try:
            super().finish()
        finally:
            self.server.untrack_socket(self.connection)

    def log_message(self, fmt, *args):
        # Do not persist URLs or request headers.
        pass

    def forward_absolute_request(self, method):
        try:
            path = absolute_target(self.path)
        except ValueError:
            self.send_error(403, "Only official OpenWrt HTTPS downloads are allowed")
            return
        upstream = http.client.HTTPSConnection(
            ALLOWED_HOST, 443, timeout=IO_TIMEOUT_SECONDS,
            context=ssl.create_default_context(),
        )
        response_started = False
        upstream_socket = None
        try:
            headers = {"User-Agent": "OpenWrt-download-proxy", "Connection": "close"}
            for key in ("Range", "If-Modified-Since", "If-None-Match"):
                if self.headers.get(key):
                    headers[key] = self.headers[key]
            upstream.connect()
            upstream_socket = upstream.sock
            self.server.track_socket(upstream_socket)
            upstream.request(method, path, headers=headers)
            response = upstream.getresponse()
            self.send_response(response.status)
            for key in ("Content-Type", "Content-Length", "Last-Modified", "ETag",
                        "Content-Range", "Accept-Ranges", "Location"):
                value = response.getheader(key)
                if value is not None:
                    self.send_header(key, value)
            self.send_header("Connection", "close")
            self.end_headers()
            response_started = True
            if method != "HEAD":
                while chunk := response.read(65536):
                    self.wfile.write(chunk)
        except (OSError, http.client.HTTPException):
            if not response_started:
                self.send_error(502, "Official download connection failed")
        finally:
            if upstream_socket is not None:
                self.server.untrack_socket(upstream_socket)
            upstream.close()
            self.close_connection = True

    def do_GET(self):
        self.forward_absolute_request("GET")

    def do_HEAD(self):
        self.forward_absolute_request("HEAD")

    def do_CONNECT(self):
        try:
            address = connect_target(self.path)
        except ValueError:
            self.send_error(403, "Only official OpenWrt HTTPS downloads are allowed")
            return
        try:
            upstream = socket.create_connection(address, timeout=15)
        except OSError:
            self.send_error(502, "Official download connection failed")
            return
        upstream.settimeout(IO_TIMEOUT_SECONDS)
        self.server.track_socket(upstream)
        try:
            self.send_response(200, "Connection Established")
            self.end_headers()
            self.wfile.flush()
            connections = [self.connection, upstream]
            while True:
                readable, _, _ = select.select(connections, [], [], 60)
                if not readable:
                    break
                for source in readable:
                    chunk = source.recv(65536)
                    if not chunk:
                        return
                    target = upstream if source is self.connection else self.connection
                    target.sendall(chunk)
        except OSError:
            pass
        finally:
            self.server.untrack_socket(upstream)
            upstream.close()
            self.close_connection = True


def main():
    try:
        server = ProxyServer()
    except OSError:
        raise SystemExit("Cannot listen on 127.0.0.1:18080; check whether the port is in use.") from None
    timer = threading.Timer(LIFETIME_SECONDS, server.shutdown)
    timer.daemon = True
    timer.start()
    print("Listening on http://127.0.0.1:18080", flush=True)
    print("Allowed destination: downloads.openwrt.org:443 only", flush=True)
    print("Stops after 20 minutes or Ctrl+C. Stop the SSH forwarding window separately.", flush=True)
    try:
        server.serve_forever(poll_interval=0.5)
    except KeyboardInterrupt:
        pass
    finally:
        timer.cancel()
        server.server_close()
        server.close_active_connections()
        print("Proxy stopped; local listener and active connections closed.", flush=True)


if __name__ == "__main__":
    main()
