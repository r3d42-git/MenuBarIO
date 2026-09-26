"""Exercise publication gates with fake GitHub/Git; never upload real assets."""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class PublishReleaseTests(unittest.TestCase):
    def run_case(self, failure=""):
        with tempfile.TemporaryDirectory(prefix="menubario-publish-test-") as directory:
            root = Path(directory)
            (root / "script").mkdir()
            (root / "bin").mkdir()
            (root / "RELEASE_NOTES").mkdir()
            (root / "RELEASE_NOTES/1.0.0.md").write_text("Test release\n")
            assets = root / ".release/1.0.0"
            assets.mkdir(parents=True)
            dmg = assets / "MenuBarIO-1.0.0-mac.dmg"
            dmg.write_bytes(b"verified fixture bytes")
            digest = hashlib.sha256(dmg.read_bytes()).hexdigest()
            dmg.with_suffix(".dmg.sha256").write_text(f"{digest}  {dmg.name}\n")
            source = Path(__file__).resolve().parents[1] / "publish_release.sh"
            shutil.copy2(source, root / "script/publish_release.sh")
            scripts = {
                "bin/git": '''#!/bin/bash
case "$1 $2" in
  'status --porcelain=v1') ;;
  'remote get-url') echo https://github.com/r3d42-git/MenuBarIO.git ;;
  'branch --show-current') echo main ;;
  'rev-parse '*|'ls-remote '*) echo aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa ;;
  *) exit 90 ;;
esac
''',
                "bin/gh": '''#!/bin/bash
set -eu
echo "$*" >> "$FIXTURE_ROOT/events"
case "$1 $2" in
  'release create') [[ " $* " == *' --draft '* ]] ;;
  'release edit') [[ " $* " == *' --draft=false '* ]] ;;
  'release download')
    while [[ "$1" != --dir ]]; do shift; done
    target="$2"
    cp "$FIXTURE_ROOT"/.release/1.0.0/* "$target/"
    if [[ "$FAILURE" == draft-bytes && "$target" == */draft ]] ||
       [[ "$FAILURE" == published-bytes && "$target" == */published ]]; then
      echo corrupt >> "$target/MenuBarIO-1.0.0-mac.dmg"
    fi
    if [[ "$FAILURE" == draft-checksum && "$target" == */draft ]]; then
      echo extra >> "$target/MenuBarIO-1.0.0-mac.dmg.sha256"
    fi ;;
  *) exit 91 ;;
esac
''',
                "script/verify_release.sh": '''#!/bin/bash
set -eu
echo "verify $2" >> "$FIXTURE_ROOT/events"
if [[ "$FAILURE" == draft-verifier && "$2" == */draft/* ]]; then exit 92; fi
''',
            }
            for name, content in scripts.items():
                p = root / name
                p.write_text(content)
                p.chmod(0o755)
            env = dict(os.environ, PATH=f"{root / 'bin'}:{os.environ['PATH']}",
                       FIXTURE_ROOT=str(root), FAILURE=failure)
            result = subprocess.run(["bash", "script/publish_release.sh", "1.0.0"],
                                    cwd=root, env=env, capture_output=True, text=True)
            events = (root / "events").read_text()
            return result, events

    def test_success_verifies_draft_before_publish_and_downloads_again(self):
        result, events = self.run_case()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(events.count("release download"), 2)
        draft_check = next(line for line in events.splitlines() if "verify " in line and "/draft/" in line)
        published_check = next(line for line in events.splitlines() if "verify " in line and "/published/" in line)
        self.assertLess(events.index(draft_check), events.index("release edit"))
        self.assertLess(events.index("release edit"), events.index(published_check))

    def test_draft_failures_never_publish(self):
        for failure in ("draft-bytes", "draft-checksum", "draft-verifier"):
            with self.subTest(failure=failure):
                result, events = self.run_case(failure)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn("release edit", events)

    def test_public_download_corruption_never_reports_success(self):
        result, events = self.run_case("published-bytes")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("release edit", events)
        self.assertNotIn("Published and independently verified", result.stdout)


if __name__ == "__main__":
    unittest.main()
