"""Read-only checks against the Phase E starting manifest and built artifacts."""
from pathlib import Path
import hashlib,json,subprocess,tarfile,difflib,re
root=Path(__file__).resolve().parents[2]
out=root/'audit-results/real-world-apps'
before=json.loads((out/'baseline-files.json').read_text())
changed=[];missing=[]
for relative,expected in before.items():
    path=root/relative
    if not path.exists():missing.append(relative)
    elif hashlib.sha256(path.read_bytes()).hexdigest()!=expected:changed.append(relative)
assert not missing,missing
observed_tests=['tests/testthat/test-h2-adversarial-security.R',
 'tests/testthat/test-h2-contracts.R','tests/testthat/test-h2-state-machine.R']
assert set(changed)==set(['.Rbuildignore',*observed_tests]),changed
observations=[]
with tarfile.open(out.parent/'hardening/h3-performance/final-validation-ring/build/termr_1.0.1.tar.gz') as original:
    for relative in observed_tests:
        data=original.extractfile('termr/'+relative).read()
        assert hashlib.sha256(data).hexdigest()==before[relative]
        copy=out/'preservation-baseline'/relative
        copy.parent.mkdir(parents=True,exist_ok=True);copy.write_bytes(data)
        current=(root/relative).read_bytes()
        diff=''.join(difflib.unified_diff(data.decode().splitlines(True),current.decode().splitlines(True),
            fromfile='initial/'+relative,tofile='observed/'+relative))
        (out/'preservation-baseline'/f'{Path(relative).name}.diff').write_text(diff)
        observations.append(dict(file=relative,initial_sha256=before[relative],
            current_sha256=hashlib.sha256(current).hexdigest(),
            newline_only=data.rstrip(b'\r\n')==current.rstrip(b'\r\n'),
            action='Current file retained. Origin not established; initial bytes and diff archived.'))
old=(out/'Rbuildignore-before').read_text().splitlines()
new=(root/'.Rbuildignore').read_text().splitlines()
assert new==old+['^integration-apps$','^typescript$'],new
head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
branch=subprocess.check_output(['git','branch','--show-current'],cwd=root,text=True).strip()
assert head=='1b10370d1df50e54a63706673b150feaf7b04889'
assert branch=='2.0-termr'
upstream=subprocess.check_output(['git','status','--short'],cwd=root/'integration-apps/legacy-rtop/upstream',text=True)
assert not upstream,upstream
archives=[]
candidate_r_files=0
with tarfile.open(out.parent/'hardening/h3-performance/final-validation-ring/build/termr_1.0.1.tar.gz') as installed_source:
    for member in installed_source.getmembers():
        relative='/'.join(member.name.split('/')[1:])
        if member.isfile() and relative.startswith('R/'):
            assert installed_source.extractfile(member).read().replace(b'\r\n',b'\n')==(root/relative).read_bytes().replace(b'\r\n',b'\n'),relative
            candidate_r_files+=1
def dcf(data):
    fields={};key=None
    for line in data.decode().replace('\r','').splitlines():
        if not line.strip():continue
        if line[0].isspace():fields[key]+=' '+line.strip()
        else:key,value=line.split(':',1);fields[key]=value.strip()
    return {key:re.sub(r'\s+',' ',value).strip() for key,value in fields.items()}
for platform in ['windows','wsl']:
    archive=out/f'check-{platform}'/'termr_1.0.1.tar.gz'
    with tarfile.open(archive) as tar:
        names=tar.getnames()
        assert not any('/integration-apps' in name or '/typescript' in name or '/audit-results' in name for name in names)
        checked=[]
        for member in tar.getmembers():
            relative='/'.join(member.name.split('/')[1:])
            if member.isfile() and (relative.startswith(('R/','man/','tests/')) or relative in ['DESCRIPTION','NAMESPACE']):
                built=tar.extractfile(member).read().replace(b'\r\n',b'\n')
                current=(root/relative).read_bytes().replace(b'\r\n',b'\n')
                if relative=='DESCRIPTION':
                    actual=dcf(built);expected=dcf(current)
                    assert all(actual.get(key)==value for key,value in expected.items()),(platform,'DESCRIPTION fields')
                    assert set(actual)-set(expected)<=set(['NeedsCompilation','Packaged','Author','Maintainer'])
                else:assert built==current,(platform,relative)
                checked.append(relative)
    archives.append(dict(platform=platform,sha256=hashlib.sha256(archive.read_bytes()).hexdigest(),
        entries=len(names),verified_source_files=len(checked),application_runtime_excluded=True))
result=dict(status='VERIFIED_WITH_OBSERVED_TEST_CHANGES',initial_files=len(before),preserved_unchanged=len(before)-len(changed),
    intentional_existing_change=['.Rbuildignore'],observed_test_changes=observations,
    head=head,branch=branch,upstream_clean=True,archives=archives,
    installed_candidate_archive_r_files_verified=candidate_r_files,
    public_api_and_core_unchanged=True)
(out/'preservation-results.json').write_text(json.dumps(result,indent=2))
(out/'git-status-after.txt').write_text(subprocess.check_output(['git','status','--short'],cwd=root,text=True))
diff=subprocess.run(['git','diff','--check'],cwd=root,capture_output=True,text=True)
(out/'git-diff-check.txt').write_text(diff.stdout+diff.stderr)
(out/'git-diff-check.exit').write_text(str(diff.returncode)+'\n')
assert diff.returncode==0,diff.stdout+diff.stderr
print(json.dumps(result,indent=2))
