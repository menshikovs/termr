from pathlib import Path
out = Path('audit-results/hardening/h3-performance')
source = (out/'run-wsl-final.sh').read_text()
start = source.index('root="$PWD"')
end = source.index('mkdir -p /tmp/termr-h3-lib', start)
replacement = '''root="$PWD"
candidate="$PWD/$out/final-validation/build/termr_1.0.1.tar.gz"
test -f "$candidate" || exit 3
mkdir -p /tmp/termr-h3-source /tmp/termr-h3-build "$out/build-wsl"
tar -xzf "$candidate" -C /tmp/termr-h3-source || exit 3
(cd /tmp/termr-h3-build && R CMD build --no-build-vignettes --no-manual /tmp/termr-h3-source/termr) > "$out/build-wsl.log" 2>&1
build_status=$?
echo "$build_status" > "$out/build-wsl.exit"
test "$build_status" -eq 0 || exit 3
cp /tmp/termr-h3-build/termr_1.0.1.tar.gz "$out/build-wsl/termr_1.0.1.tar.gz"
archive="$PWD/$out/build-wsl/termr_1.0.1.tar.gz"
'''
(out/'run-wsl-staged.sh').write_bytes((source[:start]+replacement+source[end:]).encode())
