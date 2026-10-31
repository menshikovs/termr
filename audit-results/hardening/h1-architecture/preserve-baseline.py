from pathlib import Path
import csv
import hashlib
import io
import json
import re
import subprocess

root = Path.cwd()
out = root / "audit-results/hardening/h1-architecture"
baseline = list(csv.DictReader((out / "baseline-files.csv").read_text(encoding="utf-8-sig").splitlines()))
pilot_added = [
    b"      startup_complete <- FALSE\n      on.exit(if (!startup_complete) {\n        try(private$app_private()$shutdown(), silent = TRUE)\n      }, add = TRUE)\n",
    b"      startup_complete <- TRUE\n",
    b"#' Internal headless app pilot\n#' @noRd\n",
]
cache_new = (
    b"      # Column names are arbitrary strings; delimiters alone can alias a\n"
    b"      # multi-column projection with one name containing that delimiter.\n"
    b'      columns_key <- paste0(nchar(columns, type = "bytes"), ":", columns, collapse = "")\n'
    b'      key <- paste(start, count, columns_key, sep = "|")\n'
)
cache_old = b'      key <- paste(start, count, paste(columns, collapse = "\\r"), sep = "|")\n'


def sha(data):
    return hashlib.sha256(data).hexdigest().upper()


records = []
for row in baseline:
    path = root / row["Path"]
    current = path.read_bytes() if path.exists() else b""
    current_hash = sha(current)
    expected = row["SHA256"].upper()
    status = "unchanged"
    reverse = current
    if current_hash != expected:
        if row["Path"] == "R/testing.R":
            for snippet in pilot_added:
                assert reverse.count(snippet) == 1
                reverse = reverse.replace(snippet, b"", 1)
        elif row["Path"] == "R/widget-datatable.R":
            assert reverse.count(cache_new) == 1
            reverse = reverse.replace(cache_new, cache_old, 1)
        else:
            raise RuntimeError("Unexpected baseline change: " + row["Path"])
        assert sha(reverse) == expected, "Changes beyond H1 patch: " + row["Path"]
        status = "H1 patch; reversing only H1 additions exactly restores baseline hash"
    records.append(dict(Path=row["Path"], BeforeSHA256=expected, AfterSHA256=current_hash, Preservation=status))

with (out / "preservation.csv").open("w", encoding="utf-8", newline="") as stream:
    writer = csv.DictWriter(stream, fieldnames=list(records[0]))
    writer.writeheader()
    writer.writerows(records)


def git(*args):
    return subprocess.run(["git", *args], cwd=root, capture_output=True, text=True, check=True).stdout


metadata = dict(head=git("rev-parse", "HEAD").strip(), branch=git("branch", "--show-current").strip(),
                baseline_files=len(records), unchanged=sum(r["Preservation"] == "unchanged" for r in records),
                changed=[r["Path"] for r in records if r["Preservation"] != "unchanged"],
                staged_numstat=git("diff", "--cached", "--numstat"))
assert metadata["head"] == "1b10370d1df50e54a63706673b150feaf7b04889"
assert metadata["branch"] == "2.0-termr"
assert metadata["staged_numstat"] == ""
archive_digests = []
for name in ("build-archive-sha256.txt", "archive-sha256-wsl.txt"):
    raw = (out / name).read_bytes()
    text = raw.decode("utf-16" if raw.startswith((b"\xff\xfe", b"\xfe\xff")) else "utf-8-sig")
    archive_digests.append(re.search(r"\b[0-9a-fA-F]{64}\b", text).group(0).upper())
assert archive_digests[0] == archive_digests[1]
metadata["windows_wsl_source_archive_sha256"] = archive_digests[0]
(out / "git-status-after.txt").write_text(git("status", "--short"), encoding="utf-8")
(out / "preservation-summary.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")
print(json.dumps(metadata, indent=2))
