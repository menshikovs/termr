"""Verify the E-FIX starting tree and current package archives without Git writes."""
from pathlib import Path
import hashlib,json,subprocess,tarfile,re
root=Path(__file__).resolve().parents[2]
out=root/'audit-results/real-world-apps/e-fix'
before=json.loads((out/'baseline-files.json').read_text())
changed=[]
for file,digest in before.items():
    path=root/file
    assert path.is_file(),('Missing initial file',file)
    if hashlib.sha256(path.read_bytes()).hexdigest()!=digest:changed.append(file)
assert all(file.startswith(('integration-apps/','tools/integration/')) for file in changed),changed
assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=root).strip()==(out/'git-head-before.txt').read_bytes().strip()
assert subprocess.check_output(['git','diff','--cached','--binary'],cwd=root)==(out/'git-staged-before.patch').read_bytes()
def dcf(data):
    fields={};key=None
    for line in data.decode().replace('\r','').splitlines():
        if not line.strip():continue
        if line[0].isspace():fields[key]+=' '+line.strip()
        else:key,value=line.split(':',1);fields[key]=value.strip()
    return {key:re.sub(r'\s+',' ',value).strip() for key,value in fields.items()}
archives=[]
for platform in ['windows','wsl']:
    path=out/f'final-check-{platform}'/'termr_1.0.1.tar.gz'
    checked=0
    with tarfile.open(path) as tar:
        assert not any('/integration-apps' in name or '/audit-results' in name for name in tar.getnames())
        for member in tar.getmembers():
            file='/'.join(member.name.split('/')[1:])
            if member.isfile() and (file.startswith(('R/','man/','tests/')) or file in ['DESCRIPTION','NAMESPACE']):
                data=tar.extractfile(member).read().replace(b'\r\n',b'\n')
                current=(root/file).read_bytes().replace(b'\r\n',b'\n')
                if file=='DESCRIPTION':
                    expected=dcf(current);actual=dcf(data)
                    assert all(actual.get(key)==value for key,value in expected.items())
                else:assert data==current,(platform,file)
                checked+=1
    archives.append(dict(platform=platform,checked_files=checked,sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
diff=subprocess.run(['git','diff','--check'],cwd=root,text=True,capture_output=True)
(out/'git-diff-check.log').write_text(diff.stdout+diff.stderr)
assert diff.returncode==0,diff.stdout
(out/'git-status-after.txt').write_bytes(subprocess.check_output(['git','status','--short'],cwd=root))
result=dict(status='PASS',initial_files=len(before),changed_initial_files=changed,
    core_api_docs_H1_H2_H3_unchanged=True,index_unchanged=True,head_unchanged=True,
    git_diff_check_exit=diff.returncode,archives=archives)
(out/'preservation.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
