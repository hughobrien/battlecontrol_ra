import argparse
import os
import signal
import subprocess
import time
from pathlib import Path

RA_PATH = "./zig-out/bin/ra"

launcher_state = None


def pick_display(first=80, last=89):
    for number in range(first, last + 1):
        lock = Path(f"/tmp/battlecontrol-xdisplay-{number}.lock")
        if Path(f"/tmp/.X{number}-lock").exists():
            continue
        if Path(f"/tmp/.X11-unix/X{number}").exists():
            continue
        try:
            fd = os.open(lock, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
        except FileExistsError:
            continue
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(f"{os.getpid()} {int(time.time())}\n")
        return number, lock
    raise RuntimeError("no free X display in :80..:89")


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
    parser.add_argument("--xvfb", required=True)
    parser.add_argument("game_args", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    if args.game_args[:1] == ["--"]:
        args.game_args = args.game_args[1:]
    return args


def game_args(args):
    return [RA_PATH, "--assets", args.assets, "--skip-intro", *args.game_args]


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
