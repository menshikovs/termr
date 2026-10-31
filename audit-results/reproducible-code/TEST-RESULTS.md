# Результаты тестирования A4

Дата прогона: 2026-10-31. Все проверки выполнялись над текущей рабочей
копией; сторонние пользовательские изменения сохранены. Исходное состояние
зафиксировано в `BASELINE.md`.

## A4 и регрессии

| Среда / команда | Результат |
|---|---|
| Windows R 4.6.1: `testthat::test_local('.', filter = 'datatable-reproducible-code', reporter = 'summary')` | PASS; optional `bit64`, `haven`, `units`, `lubridate`, `blob`, `hms`, `sf` пропущены, поскольку они не установлены |
| Windows: `testthat::test_local('.', filter = 'windows-driver\|mouse\|paste\|unicode\|graphemes\|platform-bounds', reporter = 'summary')` | PASS |
| Windows: `Rscript tools/dev.R test` | 15,045 checks; 0 failures, 17 errors, 94 skips, 0 warnings. Ошибки — дочерние processx процессы: `system error 5, Access is denied` при создании pipe. |
| Windows R CMD check, staged tarball, `_R_CHECK_FORCE_SUGGESTS_=false`, `LC_*` очищены | Код, загрузка, зависимости, Rd и примеры — OK; тестовая часть даёт 17 processx ошибок. Итог `1 ERROR`, 0 summary WARNING/NOTE от пакета. В test run: 11,290 pass, 17 fail, 127 skip. Лог: `windows-final-v3-check/termr.Rcheck/00check.log`. |
| WSL Ubuntu R 4.5.2: `Rscript tools/dev.R test` | 16,818 checks; 0 failures, 0 errors, 29 skips, 0 warnings. Optional `mirai`/`nanonext` отсутствуют. |
| WSL R CMD build + check | Финальная staged сборка и финальный check после roxygen regeneration прошли; `Status: OK`, включая пакетные тесты. Не установлены `mirai`/`nanonext`. См. `wsl-final-v2-check/`. |
| Optional source examples | WSL Arrow local Dataset helper вернул `exact`; DuckDB/dbplyr helper корректно сообщил, что не установлен optional `duckdb`, и не обращался к remote source. Полный код примера смотрит `validate-sample-examples.R`. |
| WSL PTY `python3 tools/pty/pty-check-ci.py` | Большинство проверок PASS; два отказа в `combined_focus_session`: одновременная запись текста, Tab и Enter не регистрирует Enter. Изолированный повтор подтвердил те же два отказа. Остальные controlling-TTY, stdin-only, no-TTY, терминальное восстановление и управляющие последовательности прошли. Логи: `wsl-pty.log`, `wsl-pty-combined.log`. |
| WSL PTY `python3 tools/pty/pty-check-ci.py --exclude-case combined_focus_session` | PASS для оставшихся stdin-fallback и no-TTY сценариев; лог `wsl-pty-rest.log`. |
| `R CMD check` проверки документации/namespace | Rd files, метаданные, cross-references, usage, contents и примеры — OK. Отдельных A4 NAMESPACE exports не добавлено. |
| `git diff --check` | PASS; см. итоговый статус в корневом отчёте A4 ниже. |

Первый focused Windows прогон под унаследованными `LC_* = C.UTF-8` ошибся на
сравнении UTF-8 значения: такая locale отсутствует на Windows. После очистки
этих неподдерживаемых переменных тот же focused A4 фильтр прошёл. Проверка
Windows unicode/input parser также прошла при текущей Windows UTF-8 session
charset.

Windows failures отделены от A4 сценариев: причина одинаковая в полном
testthat и R CMD check — processx не получает право создавать дочерние pipes
к `cmd.exe` в этом sandbox. Финальную проверку повторили после удаления
унаследованных Windows-несовместимых `LC_* = C.UTF-8`; повтор прошёл
DESCRIPTION/код/Rd/examples и дошёл до тех же processx ошибок. Этот запуск не
доказывает, что проблема была в исходной baseline: полная проверка Windows до
начала A4 не выполнялась.

Roxygen regeneration обновила `DataTable-class.Rd`. Команда выводит
существующие предупреждения Pilot R6-документации (недокументированные поля,
методы и аргументы); новые DataTable методы появились в generated Rd, а
R CMD check считает справку корректной.
