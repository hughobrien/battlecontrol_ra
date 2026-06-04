import argparse
import os
import signal
import subprocess
import time
from pathlib import Path

RA_PATH = "./zig-out/bin/ra"

launcher_state = None


def process_owns_lock(pid):
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True

    try:
        status = Path(f"/proc/{pid}/status").read_text(encoding="utf-8")
    except OSError:
        return True
    for line in status.splitlines():
        if line.startswith("State:"):
            return "\tZ" not in line and "zombie" not in line
    return True


def reclaim_stale_display_lock(lock):
    try:
        contents = lock.read_text(encoding="utf-8").split()
    except FileNotFoundError:
        return True
    except OSError:
        return False

    if not contents:
        return False

    try:
        owner = int(contents[0])
    except ValueError:
        return False

    if not process_owns_lock(owner):
        try:
            lock.unlink()
        except FileNotFoundError:
            return True
        except OSError:
            return False
        return True

    return False


def unlink_if_exists(path):
    try:
        path.unlink()
    except FileNotFoundError:
        pass


def try_pick_display(first, last, tmp_dir):
    socket_dir = tmp_dir / ".X11-unix"
    for number in range(first, last + 1):
        lock = tmp_dir / f"battlecontrol-xdisplay-{number}.lock"
        x_lock = tmp_dir / f".X{number}-lock"
        x_socket = socket_dir / f"X{number}"
        if x_lock.exists():
            if reclaim_stale_display_lock(x_lock):
                unlink_if_exists(x_socket)
            else:
                continue
        if x_socket.exists():
            continue
        reclaim_stale_display_lock(lock)
        try:
            fd = os.open(lock, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
        except FileExistsError:
            continue
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(f"{os.getpid()} {int(time.time())}\n")
        return number, lock
    return None


def pick_display(first=80, last=99, tmp_dir=Path("/tmp"), attempts=20, retry_delay=0.5):
    for attempt in range(attempts):
        picked = try_pick_display(first, last, tmp_dir)
        if picked is not None:
            return picked
        if attempt + 1 < attempts:
            time.sleep(retry_delay)
    raise RuntimeError("no free X display in :80..:99")


def stop_process(process):
    if process is None or process.poll() is not None:
        return
    process.terminate()
    try:
        process.wait(timeout=2)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait()


def cleanup_display(state):
    if state["cleaned"]:
        return
    state["cleaned"] = True
    try:
        state["lock"].unlink()
    except FileNotFoundError:
        pass
    stop_process(state["build"])
    stop_process(state["game"])
    stop_process(state["xvfb"])
    for path in (
        Path(f"/tmp/.X{state['number']}-lock"),
        Path(f"/tmp/.X11-unix/X{state['number']}"),
    ):
        try:
            path.unlink()
        except FileNotFoundError:
            pass


def handle_signal(signum, _frame):
    if launcher_state is not None:
        cleanup_display(launcher_state)
    raise SystemExit(128 + signum)


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--assets", required=True)
    parser.add_argument("--build-app", required=True)
    parser.add_argument("--side", choices=("allied", "soviet"), required=True)
    parser.add_argument("--xvfb", required=True)
    parser.add_argument("game_args", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    if args.game_args[:1] == ["--"]:
        args.game_args = args.game_args[1:]
    return args


def game_args(args):
    return [
        RA_PATH,
        "--assets",
        args.assets,
        "--side",
        args.side,
        "--skip-intro",
        *args.game_args,
    ]


def main():
    global launcher_state

    args = parse_args()
    number, lock = pick_display()
    display = f":{number}"
    launcher_state = {
        "build": None,
        "cleaned": False,
        "game": None,
        "lock": lock,
        "number": number,
        "xvfb": None,
    }
    try:
        for signum in (signal.SIGHUP, signal.SIGINT, signal.SIGTERM):
            signal.signal(signum, handle_signal)

        launcher_state["xvfb"] = subprocess.Popen(
            [args.xvfb, display, "-screen", "0", "640x400x24", "-ac"]
        )
        time.sleep(1)

        launcher_state["build"] = subprocess.Popen([args.build_app])
        if launcher_state["build"].wait() != 0:
            return launcher_state["build"].returncode

        env = os.environ.copy()
        env["DISPLAY"] = display
        env.setdefault("SDL_AUDIODRIVER", "dummy")
        env.pop("WAYLAND_DISPLAY", None)

        launcher_state["game"] = subprocess.Popen(game_args(args), env=env)
        return launcher_state["game"].wait()
    finally:
        cleanup_display(launcher_state)


if __name__ == "__main__":
    raise SystemExit(main())
