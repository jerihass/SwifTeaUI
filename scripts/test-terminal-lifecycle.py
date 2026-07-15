#!/usr/bin/env python3
"""Exercise SwifTeaUI terminal ownership through a real pseudo-terminal."""

import argparse
import fcntl
import os
import pty
import select
import signal
import struct
import subprocess
import termios
import time


HIDE_CURSOR = b"\x1b[?25l"
SHOW_CURSOR = b"\x1b[?25h"
ENABLE_BRACKETED_PASTE = b"\x1b[?2004h"
DISABLE_BRACKETED_PASTE = b"\x1b[?2004l"


def read_until(master: int, process: subprocess.Popen[bytes], marker: bytes, timeout: float = 5.0) -> bytes:
    output = bytearray()
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        readable, _, _ = select.select([master], [], [], 0.05)
        if readable:
            try:
                output.extend(os.read(master, 65536))
            except OSError:
                pass
            if marker in output:
                return bytes(output)
        if process.poll() is not None:
            break
    raise AssertionError(
        f"fixture did not emit {marker!r}; status={process.poll()} output={bytes(output)!r}"
    )


def drain(master: int, timeout: float = 0.25) -> bytes:
    output = bytearray()
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        readable, _, _ = select.select([master], [], [], 0.02)
        if not readable:
            continue
        try:
            output.extend(os.read(master, 65536))
        except OSError:
            break
    return bytes(output)


def comparable_attributes(attributes: list[object]) -> list[object]:
    normalized = attributes.copy()
    # Darwin reports PENDIN after canonical mode is re-enabled. It is terminal-driver
    # state, not a user-configurable setting, and clears when the next read is processed.
    normalized[3] = int(normalized[3]) & ~getattr(termios, "PENDIN", 0)
    return normalized


def run_case(
    binary: str,
    *,
    key: bytes | None = None,
    sent_signal: int | None = None,
    environment: dict[str, str] | None = None,
    resize: tuple[int, int] | None = None,
    sessions: int = 1,
    initially_nonblocking: bool = False,
) -> bytes:
    master, slave = pty.openpty()
    fcntl.ioctl(master, termios.TIOCSWINSZ, struct.pack("HHHH", 24, 80, 0, 0))
    if initially_nonblocking:
        flags = fcntl.fcntl(slave, fcntl.F_GETFL)
        fcntl.fcntl(slave, fcntl.F_SETFL, flags | os.O_NONBLOCK)
    before_attributes = termios.tcgetattr(slave)
    before_flags = fcntl.fcntl(slave, fcntl.F_GETFL)
    env = os.environ.copy()
    env["SWIFT_BACKTRACE"] = "enable=no"
    env.update(environment or {})
    if sessions == 2:
        env["SWIFTEA_LIFECYCLE_SESSIONS"] = "2"

    process = subprocess.Popen(
        [binary],
        stdin=slave,
        stdout=slave,
        stderr=slave,
        env=env,
        start_new_session=True,
    )
    output = bytearray()
    try:
        output.extend(read_until(master, process, b"session=1"))
        active_flags = fcntl.fcntl(slave, fcntl.F_GETFL)

        if resize is not None:
            columns, rows = resize
            fcntl.ioctl(master, termios.TIOCSWINSZ, struct.pack("HHHH", rows, columns, 0, 0))
            os.kill(process.pid, signal.SIGWINCH)
            output.extend(read_until(master, process, f"size={columns}x{rows}".encode()))

        if key is not None:
            os.write(master, key)
        elif sent_signal is not None:
            os.kill(process.pid, sent_signal)
        else:
            raise AssertionError("case needs a key or signal")

        if sessions == 2:
            output.extend(read_until(master, process, b"session=2"))
            os.write(master, key or b"q")

        try:
            status = process.wait(timeout=5.0)
        except subprocess.TimeoutExpired as error:
            output.extend(drain(master))
            raise AssertionError(f"fixture did not exit; output={bytes(output)!r}") from error
        output.extend(drain(master))

        expected_status = -sent_signal if sent_signal is not None else 0
        assert status == expected_status, (status, expected_status, bytes(output))
        after_attributes = termios.tcgetattr(slave)
        assert comparable_attributes(after_attributes) == comparable_attributes(before_attributes), (
            "terminal attributes were not restored",
            before_attributes,
            after_attributes,
        )
        after_flags = fcntl.fcntl(slave, fcntl.F_GETFL)
        mutable_flags = os.O_APPEND | os.O_NONBLOCK | getattr(os, "O_ASYNC", 0)
        assert after_flags & mutable_flags == before_flags & mutable_flags, (
            "mutable file flags were not restored",
            before_flags,
            active_flags,
            after_flags,
        )
        assert output.count(HIDE_CURSOR) == sessions, bytes(output)
        assert output.count(SHOW_CURSOR) == sessions, bytes(output)
        assert output.count(ENABLE_BRACKETED_PASTE) == sessions, bytes(output)
        assert output.count(DISABLE_BRACKETED_PASTE) == sessions, bytes(output)
        return bytes(output)
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()
        os.close(master)
        os.close(slave)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("binary")
    args = parser.parse_args()
    binary = os.path.abspath(args.binary)

    run_case(binary, key=b"q")
    run_case(binary, key=b"q", initially_nonblocking=True)
    run_case(binary, key=b"\x03")
    run_case(binary, key=b"\x1b[200~quit\x1b[201~")
    run_case(binary, key=b"q", environment={"SWIFTEA_LIFECYCLE_THROW": "1"})
    run_case(binary, key=b"q", resize=(101, 33))
    run_case(binary, key=b"q", sessions=2)
    for sent_signal in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP, signal.SIGQUIT):
        run_case(binary, sent_signal=sent_signal)

    print("terminal lifecycle: all PTY cases passed")


if __name__ == "__main__":
    main()
