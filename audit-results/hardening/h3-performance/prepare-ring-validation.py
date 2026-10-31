from pathlib import Path
import tempfile, tarfile, shutil, json
out = Path('audit-results/hardening/h3-performance')
stage = Path(tempfile.mkdtemp(prefix='staged-package-ring-', dir=out)).absolute()
with tarfile.open(out/'final-validation/build/termr_1.0.1.tar.gz') as archive:
    archive.extractall(stage, filter='data')
root = stage/'termr'
files = []
for folder in ['R','tests']:
    for file in Path(folder).rglob('*.R'):
        target = root / file
        target.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(file,target)
        files.append(file.as_posix())
(out/'ring-stage.json').write_text(json.dumps(dict(path=str(root),overlaid_sources=files),indent=2))
(out/'ring-stage-path.txt').write_text(str(root))
ps = (out/'run-windows.ps1').read_text().replace("'audit-results\\hardening\\h3-performance'", "'audit-results\\hardening\\h3-performance\\final-validation-ring'")
ps = ps.replace('termr-h3-validation', 'termr-h3-ring-validation')
ps = ps.replace('Push-Location -LiteralPath $h1out', "$h3stage = Get-Content -Raw -LiteralPath (Join-Path $h1root 'audit-results/hardening/h3-performance/ring-stage-path.txt')\nPush-Location -LiteralPath $h1out")
ps = ps.replace('build --no-build-vignettes --no-manual $h1root', 'build --no-build-vignettes --no-manual $h3stage')
(out/'run-windows-ring.ps1').write_text(ps)
sh = (out/'run-wsl-staged.sh').read_text()
sh = sh.replace('out=audit-results/hardening/h3-performance', 'base=audit-results/hardening/h3-performance\nout=$base/final-validation-ring\nmkdir -p "$out"')
sh = sh.replace('$PWD/$out/final-validation/build/', '$PWD/$base/final-validation/build/')
sh = sh.replace('termr-h3-', 'termr-h3-ring-')
sh = sh.replace('tar -xzf "$candidate" -C /tmp/termr-h3-ring-source || exit 3',
    'tar -xzf "$candidate" -C /tmp/termr-h3-ring-source || exit 3\ncp "$root"/R/*.R /tmp/termr-h3-ring-source/termr/R/\ncp -R "$root"/tests/. /tmp/termr-h3-ring-source/termr/tests/')
sh = sh.replace('Rscript "$out/platform-inventory.R"', 'Rscript "$base/platform-inventory.R"')
sh = sh.replace('Rscript "$out/resource-cycles.R"', 'Rscript "$base/resource-cycles.R"')
(out/'run-wsl-ring.sh').write_bytes(sh.encode())
print(root)
