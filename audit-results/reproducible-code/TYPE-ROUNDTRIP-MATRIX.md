# Матрица round-trip типов

`exact` означает, что тест восстановил класс, storage type, значения и
атрибуты для конкретного перечисленного представления. Whitelist закрытый;
неизвестный класс не форматируется и не приводится к character молча.

| Значение | Результат | Зависимость / примечание |
|---|---|---|
| logical, integer, double, character, raw | Exact | Сохраняются `NA`, `NaN`, ±`Inf`, пустые векторы и байты |
| factor, ordered | Exact | Сохраняются levels, class, `NA` |
| Date, POSIXct/POSIXt, difftime | Exact | Сохраняются числовая точность и атрибуты, включая timezone |
| data.frame, tibble | Exact | Имена, порядок, row names и column attributes |
| Вложенный list-column с raw/NULL | Exact для plain list | Сериализация ограничена строками/байтами/глубиной; класс `AsIs` не входит в whitelist |
| `hms` | Exact | Optional `hms` |
| `units` | Exact | Optional `units`; метаданные единиц сериализуются как атрибуты |
| `haven_labelled`, `haven_labelled_spss` | Exact | Optional `haven`; tagged NA создаётся через `haven::tagged_na()` |
| `integer64` | Exact | Optional `bit64`; значения генерируются через десятичные строки |
| lubridate `Period`, `Duration`, `Interval` | Exact по слотам | Optional `lubridate`; генерация использует `methods::new()` |
| `blob` | Exact | Optional `blob`; большие данные ограничены общим byte limit |
| `sf`, `sfc`, `sfg`, `bbox`, `crs`, `symbolic_units` | Exact только для проверенных структур | Optional `sf`/`units`; геометрия может быстро превысить лимит |
| Произвольный пользовательский класс, closure, environment, external pointer | Unsupported | Могут включать process-local или исполняемое состояние |
| Составной объект глубже 40 уровней | Unsupported | Защита от рекурсивного роста |

### Исполненные проверки

Windows R 4.6.1 прошёл базовую матрицу; optional-тесты пропущены, поскольку
на этой установке отсутствуют `bit64`, `haven`, `units`, `lubridate`, `blob`,
`hms` и `sf`. На WSL Ubuntu R 4.5.2 optional A4 round-trip тесты выполнились
для установленных типов; отсутствовали только `mirai` и `nanonext`.
Детальные команды и статус платформ приведены в `TEST-RESULTS.md` и
`WINDOWS-WSL.md`.

Для типов с optional-пакетом сгенерированный текст включает `requireNamespace`
guard. Пакет не устанавливается автоматически; если его нет, запуск кода
заканчивается понятной ошибкой.
