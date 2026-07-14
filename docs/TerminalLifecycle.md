# Terminal Lifecycle

## Purpose

SwifTeaUI owns the terminal only while `SwifTea.brew` is running. The runtime must leave a shell with its
input mode, mutable file flags, cursor visibility, and catchable signal behavior restored regardless of how
the application session ends.

## Responsibilities

The internal `TerminalSession` is the single owner of process-level terminal changes. It:

- snapshots the original `termios` attributes and file status flags;
- disables canonical input, echo, and terminal-generated signals;
- enables nonblocking input while retaining all pre-existing status flags;
- hides the cursor when standard output is a terminal;
- owns resize and termination signal registrations;
- restores each resource exactly once, even if cleanup is requested repeatedly.

The session is intentionally internal. Applications continue to use `SwifTea.brew`, `KeyEvent`, and scene
exit actions rather than coordinating POSIX state themselves.

## Exit behavior

| Event | Runtime behavior |
| --- | --- |
| Scene exit action | Stop the loop, cancel effects, restore the terminal, and return normally. |
| Typed Ctrl-C (`0x03`) | Decode `.ctrlC`; the application decides whether that action exits. |
| SIGINT, SIGTERM, SIGHUP, or SIGQUIT delivered to the process | Record the signal, stop the loop, restore the terminal and prior signal dispositions, then re-raise the signal. |
| Error thrown by `Effect.run` | Contain the error; the runtime and terminal session remain active. |

Re-raising an external signal preserves conventional process status for shells and supervisors. Existing
signal dispositions are restored before the signal is raised, so an embedding process's prior handler or
ignore policy remains authoritative.

SIGKILL and SIGSTOP cannot be caught by a process. A host crash, power loss, or terminal-emulator failure
can also prevent in-process cleanup. SwifTeaUI cannot guarantee restoration for those events; users can use
their shell's `reset` or `stty sane` recovery tools if the operating system cannot run cleanup code.

## Resize behavior

The terminal session owns SIGWINCH registration. A resize marks dimensions stale and requests a render.
Stopping a session cancels that registration and restores the previous disposition, allowing multiple
`brew` sessions in one process without accumulating handlers.

## Tradeoffs

- Disabling `ISIG` makes Ctrl-C a portable application key instead of an unconditional process interrupt.
  Applications should map `.ctrlC` to their quit action when that convention is desired.
- Input pending at shutdown is flushed before canonical mode is restored. This prevents partial escape
  sequences or repeated keys from leaking into the parent shell.
- Signal notification uses `DispatchSourceSignal`, keeping asynchronous signal callbacks out of Swift
  business logic while retaining standard POSIX dispositions at the process boundary.

## Verification

`scripts/test-terminal-lifecycle.py` launches the lifecycle fixture in real pseudo-terminals and verifies:

- normal quit and typed Ctrl-C;
- restoration when an effect throws;
- live resize handling;
- repeated sessions in one process;
- cursor hide/show pairing;
- restoration of terminal attributes and mutable file status flags;
- restoration before SIGINT, SIGTERM, SIGHUP, and SIGQUIT termination.

CI runs unit, snapshot, and pseudo-terminal tests on macOS 26 and the official Swift 6.2.4 Ubuntu 22.04
container.
