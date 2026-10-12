"""Exercise authentication through the installed CLI and real HTTP server."""

import contextlib
import http.client
import os
import re
import secrets
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from urllib.parse import urlsplit


@contextlib.contextmanager
def server(binary: str, root: Path, *flags: str):
    log_path = root / "server.log"
    with log_path.open("w+") as log:
        process = subprocess.Popen(
            [
                binary,
                "--profile",
                "web",
                "--host",
                "127.0.0.1",
                "--port",
                "0",
                "--no-open",
                *flags,
            ],
            env={**os.environ, "DSH_HOME": str(root / "home")},
            stdout=log,
            stderr=subprocess.STDOUT,
        )
        try:
            deadline = time.monotonic() + 90
            while time.monotonic() < deadline:
                content = log_path.read_text()
                match = re.search(r"dsh web: (http://127\.0\.0\.1:\d+/\S*)", content)
                if match:
                    yield urlsplit(match[1]), log_path
                    return
                if process.poll() is not None:
                    raise AssertionError(
                        "dsh exited before announcing its HTTP listener"
                    )
                time.sleep(0.1)
            raise AssertionError("dsh did not announce its HTTP listener")
        finally:
            process.terminate()
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=10)


def request(port: int, path: str, headers: dict[str, str], method: str = "GET"):
    connection = http.client.HTTPConnection("127.0.0.1", port, timeout=10)
    try:
        connection.request(method, path, headers=headers)
        response = connection.getresponse()
        return response.status, dict(response.getheaders()), response.read()
    finally:
        connection.close()


def main() -> None:
    with tempfile.TemporaryDirectory(prefix="dsh-proxy-smoke-") as directory:
        root = Path(directory)
        authority = "app.example:9162"
        base = {"Host": authority}
        # Capture a real cookie and token before switching the same home to SSO.
        with server(sys.argv[1], root, "--trusted-host", authority) as (url, _):
            assert url.port is not None and url.query.startswith("token=")
            token_query = url.query
            status, headers, _ = request(url.port, "/?" + token_query, base)
            assert status == 303 and "set-cookie" in headers
            cookie = headers["set-cookie"].split(";", 1)[0]
            assert request(url.port, "/", {**base, "Cookie": cookie})[0] == 200
            status, headers, _ = request(url.port, "/connect?" + token_query, base)
            assert status == 302 and "set-cookie" in headers
            api_cookie = headers["set-cookie"].split(";", 1)[0]

        secret = secrets.token_hex(32)
        key_file = root / "proxy-secret"
        key_file.write_text(secret + "\n")
        key_file.chmod(0o600)
        with server(
            sys.argv[1],
            root,
            "--trusted-host",
            authority,
            "--trusted-proxy-secret-file",
            str(key_file),
        ) as (url, log):
            assert url.port is not None and url.query == ""
            authenticated = {**base, "X-Dsh-Proxy-Secret": secret}
            status, headers, body = request(url.port, "/", authenticated)
            assert status == 200 and b"<!doctype html>" in body
            assert "set-cookie" not in headers and secret.encode() not in body
            assert request(url.port, "/api/not-a-real-route", authenticated)[0] == 404
            for path in ["/", "/api/not-a-real-route", "/?" + token_query]:
                for extra in [
                    {},
                    {"Cookie": cookie},
                    {"Cookie": api_cookie},
                    {"X-Dsh-Proxy-Secret": "0" * 64},
                    {"X-Dsh-Proxy-Secret": secret + ", " + secret},
                ]:
                    assert request(url.port, path, {**base, **extra})[0] == 401
            # The new API enrollment endpoint must not re-enable token login.
            for extra in [{}, {"Cookie": api_cookie}, {"X-Dsh-Proxy-Secret": secret}]:
                status, headers, _ = request(
                    url.port, "/connect?" + token_query, {**base, **extra}
                )
                assert status == 401 and "set-cookie" not in headers
            for path in ["/", "/api/not-a-real-route"]:
                for extra in [
                    {"Host": "attacker.example"},
                    {"Origin": "https://attacker.example"},
                    {"Origin": "null"},
                    {"Sec-Fetch-Site": "cross-site"},
                ]:
                    assert request(url.port, path, {**authenticated, **extra})[0] == 403
                assert request(
                    url.port, path, {**authenticated, "Origin": "https://" + authority}
                )[0] in [200, 404]
            websocket = {
                "Connection": "Upgrade",
                "Upgrade": "websocket",
                "Sec-WebSocket-Key": "dGhlIHNhbXBsZSBub25jZQ==",
                "Sec-WebSocket-Version": "13",
            }
            assert request(url.port, "/api/remote.mux", {**base, **websocket})[0] == 401
            assert (
                request(url.port, "/api/remote.mux", {**authenticated, **websocket})[0]
                == 101
            )
            assert (
                request(
                    url.port,
                    "/api/remote.mux",
                    {
                        **authenticated,
                        **websocket,
                        "Origin": "https://attacker.example",
                    },
                )[0]
                == 403
            )
            # A token query is inert in proxy mode and never creates a cookie.
            status, headers, _ = request(url.port, "/?" + token_query, authenticated)
            assert status == 200 and "set-cookie" not in headers
            assert "token=" not in log.read_text() and secret not in log.read_text()
        print(
            "trusted proxy HTTP authentication passed (including legacy cookie/token rejection)"
        )


if __name__ == "__main__":
    main()
