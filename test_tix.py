"""Self-check for tix: deps, human gates, backpressure. Run: python3 test_tix.py"""
import importlib.machinery, importlib.util, os, tempfile
from pathlib import Path

d = tempfile.mkdtemp()
os.environ.update(TIX_DIR=d, TIX_WIP="1", TIX_REVIEW="1")
loader = importlib.machinery.SourceFileLoader("tix", str(Path(__file__).with_name("tix")))
spec = importlib.util.spec_from_loader("tix", loader)
tix = importlib.util.module_from_spec(spec)
loader.exec_module(tix)


def t(id, deps="", human="false"):
    Path(d, f"{id}.md").write_text(f"---\nid: {id}\ntitle: {id}\nstatus: todo\ndeps: {deps}\nhuman: {human}\n---\nbody\n")


t("A"); t("B", "A"); t("G", human="true"); t("C", "G")
assert tix.claim("w1") == 0 and tix.load(Path(d, "A.md"))[0]["owner"] == "w1-A"
assert tix.claim("w2") == 2, "WIP limit should apply"
assert tix.main(["ready"]) == 0 and not tix.is_ready(tix.load(Path(d, "B.md"))[0], tix.all_tickets())
tix.main(["submit", "A"])
assert tix.claim("w2") == 2, "review queue full -> backpressure"
tix.main(["approve", "A"])
assert tix.claim("w2") == 0  # B now ready
tix.main(["submit", "B"]); tix.main(["approve", "B"])
assert tix.claim("w3") == 1, "C waits for human gate G"
assert tix.main(["submit", "B"]) == 1, "illegal transition"
tix.main(["done", "G"])
assert tix.claim("w3") == 0 and "body" in Path(d, "C.md").read_text()
print("ok")
