"""Local phone preview. Serves only site resources; no directory listings."""
import argparse
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import re
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parent.parent


def public_files():
    files = {"index.html", "styles.css", "main.js", "songs.js"}
    # Include artwork/fonts referenced by markup, CSS, and dynamic song cards.
    for source in ("index.html", "styles.css", "main.js"):
        text = (ROOT / source).read_text(encoding="utf-8")
        files.update(re.findall(r'''(?:assets|fonts)/[^\s'"<>?#)]+''', text))
    song_list = (ROOT / "songs.js").read_text(encoding="utf-8")
    song_list = re.sub(r"/\*.*?\*/|//[^\r\n]*", "", song_list, flags=re.S)
    files.update("songs/" + name for name in re.findall(
        r'"([A-Za-z0-9][A-Za-z0-9._-]*\.txt)"', song_list))
    return files


class PreviewHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def send_head(self):
        path = unquote(urlsplit(self.path).path)
        relative = "index.html" if path == "/" else path.removeprefix("/")
        candidate = (ROOT / relative).resolve()
        if (relative not in public_files() or not candidate.is_relative_to(ROOT)
                or not candidate.is_file()):
            self.send_error(404)
            return None
        return super().send_head()

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        super().end_headers()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bind", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8742)
    args = parser.parse_args()
    with ThreadingHTTPServer((args.bind, args.port), PreviewHandler) as server:
        print(f"Phone preview: http://{args.bind}:{args.port}/", flush=True)
        server.serve_forever()
