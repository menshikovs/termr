from pathlib import Path
import subprocess, tarfile, shutil, json
root = Path.cwd()
deps = root/'integration-apps/.deps'
archive = deps/'termr-v1.0.1-source.tar'
subprocess.run(['git','archive','--format=tar','--prefix=termr/',f'--output={archive}','v1.0.1'],check=True)
target = deps/'baseline-source'
target.mkdir(exist_ok=True)
with tarfile.open(archive) as tar:
    tar.extractall(target, filter='data')
upstream = root/'integration-apps/legacy-rtop/upstream'
compat = root/'integration-apps/legacy-rtop/compat'
compat.mkdir(exist_ok=True)
shutil.copytree(upstream/'R',compat/'R',dirs_exist_ok=True)
original = (upstream/'rtop.R').read_text(encoding='utf-8')
old = 'if (!identical(installed_termr, required_termr))'
new = 'if (!installed_termr %in% c(required_termr, "2.0.0"))'
assert original.count(old) == 1
(compat/'rtop.R').write_text(original.replace(old,new),encoding='utf-8')
import difflib
out = root/'audit-results/real-world-apps'
(out/'rtop-version-gate.patch').write_text(''.join(difflib.unified_diff(original.splitlines(True),
    original.replace(old,new).splitlines(True),fromfile='upstream/rtop.R',tofile='compat/rtop.R')))
(out/'legacy-source.json').write_text(json.dumps(dict(
    rtop_commit=subprocess.check_output(['git','-C',str(upstream),'rev-parse','HEAD'],text=True).strip(),
    termr_release_tag='v1.0.1',termr_release_commit=subprocess.check_output(['git','rev-parse','v1.0.1^{commit}'],text=True).strip(),
    candidate_version='1.0.1',candidate_branch='2.0-termr',
    note='Candidate still reports 1.0.1; the original gate does not reject it. No version metadata was changed.'),indent=2))
print(target/'termr')
