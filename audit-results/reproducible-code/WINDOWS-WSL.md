# Проверки Windows и WSL

## Windows

- OS: Windows 11 x64; R 4.6.1 UCRT; session charset UTF-8.
- A4 focused tests и детерминированные Windows driver/Unicode, mouse, paste,
  grapheme и bounds тесты прошли после очистки унаследованных `LC_* = C.UTF-8`.
- Полный `Rscript tools/dev.R test`: 15,045 checks, 0 failures, 17 errors,
  94 skips, 0 warnings. Сбой — `processx_exec` / `system error 5, Access is
  denied` на Windows pipes.
- Прямой `R CMD build` из checkout не завершился, когда R пытался скопировать
  защищённые файлы в `tools/ci-work/python`. Package-equivalent stage включал
  package source, man, tests, inst, vignettes и top-level package metadata,
  исключая git/docs/audit/tooling; staged build прошёл.
- Final staged `R CMD check` с `_R_CHECK_FORCE_SUGGESTS_=false` прошёл
  загрузку, статическую проверку кода, документацию, примеры и dependency
  checks. Test part завершился теми же 17 processx ошибками; check status
  `1 ERROR`, 0 summary WARNING/NOTE. Check выполнялся из
  `windows-final-v3-check/` после очистки унаследованных Windows-
  несовместимых `LC_* = C.UTF-8`; первоначальный v2 повтор с такими `LC_*`
  остановился на DESCRIPTION и был корректно перезапущен. Сеть для установки отсутствующих
  Suggests была недоступна: `bit64`, `blob`, `DBI`, `dplyr`, `ggplot2`,
  `haven`, `hms`, `mirai`, `nanonext`, `plotly`, `promises`, `RSQLite`, `sf`,
  `shiny`, `units`.
- Windows interactive OS clipboard и реальный RStudio/Positron terminal не
  запускались. Низкоуровневый parser/Unicode suite прошёл; это не сертификат
  настоящего terminal host.

## WSL Ubuntu

- OS: Ubuntu под WSL2, Linux x86_64; R 4.5.2.
- Полный `Rscript tools/dev.R test`: 16,818 checks; 0 failures, 0 errors,
  29 skips, 0 warnings.
- Финальный package-equivalent staged `R CMD build` прошёл. Final staged
  `R CMD check --no-manual --no-build-vignettes` с
  `_R_CHECK_FORCE_SUGGESTS_=false` завершился `Status: OK`, включая полные
  testthat, examples и Rd checks. Установка optional packages не выполнялась;
  в установленном окружении отсутствуют `mirai` и `nanonext`.
- Прямой `R CMD build .` из всего checkout в WSL не дал завершённого
  результата: он долго обходил/копировал проектные tooling directories до
  применения исключений. После этого проверки продолжили в изолированном
  package-equivalent stage; только staged build считается завершённой.
- Benchmark скрипт завершился для таблиц 100, 1,000, 10,000, 100,000 и
  1,000,000 строк; все результаты exact.
- `validate-sample-examples.R`: Arrow local Dataset helper завершился со
  статусом `exact`; DuckDB/dbplyr sample helper корректно сообщил о
  неустановленном optional `duckdb` и вернул `NULL`. Прямой query export не
  проверялся, так как DataTable не имеет такого адаптера.
- POSIX PTY harness прошёл основные raw-mode, Unicode/key, resize, Ctrl+C,
  no-TTY и terminal restoration сценарии. Два повторяемых отказа остались в
  `combined_focus_session`: в одной записи `Ada\t\n` Enter не активирует
  кнопку. A4 не меняет POSIX input driver или этот harness; связь с A4 не
  установлена. Повтор `python3 tools/pty/pty-check-ci.py --exclude-case
  combined_focus_session` завершился `all PTY checks passed` для stdin-fallback
  и no-TTY сценариев.
- Логи финальной сборки/check находятся в `wsl-final-v2-check/`; PTY лог —
  `wsl-pty.log`.

## Интерпретация

WSL предоставляет полный PASS для package check текущего A4 результата.
Windows подтверждает A4 поведение и справку, но полный check остаётся
неуспешным из-за ограничения запуска дочерних процессов в этой среде.
PTY-прогон сообщает два наблюдаемых отказа независимо от package check; их
нельзя считать исправленными или скрывать под итоговым PASS.

## Команды сборки и check

В обеих системах сборка выполнялась в package-equivalent stage, содержащем
`R/`, `man/`, `tests/`, `inst/`, `vignettes/` и top-level package metadata.
Это исключило защищённые/игнорируемые project tooling directories.

```sh
R CMD build --no-manual --no-build-vignettes .
_R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-manual --no-build-vignettes termr_1.0.1.tar.gz
```

В PowerShell те же действия выполнялись через установленный `Rcmd.exe`.
Для Windows перед check были удалены process-local `LC_ALL`, `LC_CTYPE`,
`LC_COLLATE`, `LC_MONETARY` и `LC_TIME`, поскольку `C.UTF-8` не является
доступной locale в установленной Windows R.
