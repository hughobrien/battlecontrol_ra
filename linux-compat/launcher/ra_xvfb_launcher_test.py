import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

import ra_xvfb_launcher


class DisplayLockTests(unittest.TestCase):
    def test_dead_owner_lock_is_reclaimed(self):
        with tempfile.TemporaryDirectory() as tmp:
            lock = Path(tmp) / "display.lock"
            lock.write_text("999999999 0\n", encoding="utf-8")

            self.assertTrue(ra_xvfb_launcher.reclaim_stale_display_lock(lock))
            self.assertFalse(lock.exists())

    def test_live_owner_lock_is_preserved(self):
        with tempfile.TemporaryDirectory() as tmp:
            lock = Path(tmp) / "display.lock"
            lock.write_text(f"{os.getpid()} 0\n", encoding="utf-8")

            self.assertFalse(ra_xvfb_launcher.reclaim_stale_display_lock(lock))
            self.assertTrue(lock.exists())

    def test_pick_display_reclaims_dead_x_server_lock(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            socket_dir = tmp_path / ".X11-unix"
            socket_dir.mkdir()
            x_lock = tmp_path / ".X80-lock"
            x_socket = socket_dir / "X80"
            x_lock.write_text("999999999\n", encoding="utf-8")
            x_socket.touch()

            number, lock = ra_xvfb_launcher.pick_display(80, 80, tmp_path)

            self.assertEqual(80, number)
            self.assertEqual(tmp_path / "battlecontrol-xdisplay-80.lock", lock)
            self.assertFalse(x_lock.exists())
            self.assertFalse(x_socket.exists())

    def test_pick_display_uses_wider_80_range(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            socket_dir = tmp_path / ".X11-unix"
            socket_dir.mkdir()
            for number in range(80, 90):
                (tmp_path / f".X{number}-lock").write_text(
                    f"{os.getpid()}\n", encoding="utf-8"
                )
                (socket_dir / f"X{number}").touch()

            number, lock = ra_xvfb_launcher.pick_display(tmp_dir=tmp_path)

            self.assertEqual(90, number)
            self.assertEqual(tmp_path / "battlecontrol-xdisplay-90.lock", lock)

    def test_pick_display_waits_for_x_server_cleanup(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            socket_dir = tmp_path / ".X11-unix"
            socket_dir.mkdir()
            owner = subprocess.Popen(
                [sys.executable, "-c", "import time; time.sleep(0.2)"]
            )
            try:
                x_lock = tmp_path / ".X80-lock"
                x_socket = socket_dir / "X80"
                x_lock.write_text(f"{owner.pid}\n", encoding="utf-8")
                x_socket.touch()

                number, lock = ra_xvfb_launcher.pick_display(
                    80, 80, tmp_path, attempts=10, retry_delay=0.05
                )
            finally:
                owner.wait(timeout=5)

            self.assertEqual(80, number)
            self.assertEqual(tmp_path / "battlecontrol-xdisplay-80.lock", lock)


if __name__ == "__main__":
    unittest.main()
