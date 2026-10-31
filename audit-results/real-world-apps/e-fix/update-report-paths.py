from pathlib import Path
path=Path('tools/integration/write-e-fix-reports.py')
source=path.read_text(encoding='utf-8')
replacements={
 '114':'115',
 'final-runner-windows/':'proof-windows/',
 'final-gates-wsl/':'proof-wsl/terminal-gates/',
 'api-current-wsl/':'proof-wsl/',
 'web-final-windows/':'proof-windows/browser-gates/',
 'web-final-wsl/':'proof-web-wsl/',
 'web-final-*/':'proof-windows/browser-gates/ and proof-web-wsl/',
 'coverage-final/':'proof-coverage/',
 'tests-current-windows*':'proof-windows/app-test-summary-windows.json',
 'tests-current-wsl*':'proof-wsl/app-test-summary-unix.json',
 'automation-windows/':'proof-windows/',
 'performance-wsl/':'proof-wsl/',
 'automation-wsl/':'proof-wsl/',
 'lint-verified-windows/':'proof-windows/',
 'lint-current-wsl/':'proof-wsl/'
}
for old,new in replacements.items():source=source.replace(old,new)
path.write_text(source,encoding='utf-8')
