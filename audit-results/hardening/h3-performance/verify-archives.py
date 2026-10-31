from pathlib import Path
import tarfile, hashlib, json
out = Path('audit-results/hardening/h3-performance')
results = []
for name in ['final-validation-ring/build/termr_1.0.1.tar.gz', 'final-validation-ring/build-wsl/termr_1.0.1.tar.gz']:
    archive = out / name
    assert archive.exists(), archive
    files = []
    with tarfile.open(archive) as tar:
        for member in tar.getmembers():
            rel = member.name.removeprefix('termr/')
            if member.isfile() and ((rel.startswith(('R/', 'tests/')) and rel.endswith('.R')) or rel == 'NAMESPACE'):
                raw = tar.extractfile(member).read()
                disk = Path(rel).read_bytes()
                assert raw.replace(b'\r\n',b'\n') == disk.replace(b'\r\n',b'\n'), (name, rel)
                files.append(rel)
    results.append(dict(archive=name, sha256=hashlib.sha256(archive.read_bytes()).hexdigest(),
                        verified_source_files=len(files), source_files=sorted(files), mismatch=[]))
(out/'archive-source-verification.json').write_text(json.dumps(results, indent=2))
print([(r['archive'],r['verified_source_files'],r['sha256']) for r in results])
