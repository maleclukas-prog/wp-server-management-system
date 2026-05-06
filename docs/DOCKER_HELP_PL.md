# WSMS Docker Help (PL)

Ten dokument zbiera najważniejsze komendy Docker i Docker Compose do pracy z testami WSMS.

## 1. Gdzie uruchamiać komendy

Pracuj z katalogu projektu:

```bash
cd /Users/lukaszmalec/Documents/Work_grup_space/wp-server-management-system
```

Sprawdź, czy Docker działa:

```bash
docker version
docker info
```

## 2. Szybki test Dockera (zalecany)

Uruchamia pełny smoke test instalatora w Ubuntu + fixture WordPress:

```bash
bash tests/run_docker_smoke_test.sh
```

Jeśli chcesz obejrzeć kontener po teście w VS Code (widok Containers), zachowaj go zamiast usuwać automatycznie:

```bash
WSMS_DOCKER_KEEP_CONTAINER=1 bash tests/run_docker_smoke_test.sh
```

Użyj stałej nazwy kontenera debugowego:

```bash
WSMS_DOCKER_KEEP_CONTAINER=1 WSMS_DOCKER_CONTAINER_NAME=wsms-smoke-debug bash tests/run_docker_smoke_test.sh
```

Usuń kontener debugowy po zakończeniu:

```bash
docker rm -f wsms-smoke-debug
```

Co robi ten test:

- buduje obraz z `tests/docker/Dockerfile`,
- przygotowuje bezpieczną atrapę WP z `tests/fixtures/wordpress/public_html`,
- uruchamia `installers/install_wsms.sh`,
- weryfikuje podstawowe artefakty instalacji (skrypty, aliasy, crontab).

## 2.1 Rozszerzony smoke test runtime (backup/cleanup/logi)

Uruchamia rozszerzoną walidację zachowania skryptów w Dockerze:

```bash
bash tests/run_docker_runtime_smoke_test.sh
```

Zachowanie kontenera do debugowania:

```bash
WSMS_DOCKER_KEEP_CONTAINER=1 WSMS_DOCKER_CONTAINER_NAME=wsms-runtime-smoke-debug bash tests/run_docker_runtime_smoke_test.sh
```

Ten test runtime:

- instaluje WSMS w czystym kontenerze Ubuntu,
- uruchamia wybrane skrypty runtime (`wp-help`, backup lite, backup full, retention list/clean),
- dodaje stare pliki backupów i sprawdza, że tryb awaryjny zostawia dokładnie 2 najnowsze kopie,
- sprawdza widoczne komunikaty na stdout,
- sprawdza zapis logów w `~/logs/wsms/retention/retention.log` i `~/logs/wsms/sync/nas-sync.log`.

## 2.2 Pełny smoke test modułów (20/20 skryptów)

Uruchamia pełne pokrycie modułów runtime w Dockerze (wszystkie wdrażane skrypty):

```bash
bash tests/run_docker_all_modules_smoke_test.sh
```

Co ten test dodaje ponad standardowy smoke:

- wykonuje wszystkie moduły runtime instalowane przez WSMS,
- zapisuje status PASS/WARN/FAIL dla każdego skryptu,
- zapisuje output per skrypt w `/tmp/wsms-all-modules/*.out` wewnątrz kontenera,
- drukuje końcową tabelę i liczniki pass/fail.

## 2.3 Pełna mapa testów (co i kiedy uruchamiać)

Ta lista pozwala nie pominąć żadnej walidacji:

1. `bash tests/test_suite.sh`
	Zakres: składnia skryptów, format docs, wymagane pliki, regresja zachowania uninstallera.
	Uruchamiaj: przed każdym commit/PR.
2. `bash tests/run_docker_smoke_test.sh`
	Zakres: smoke ścieżki instalatora w kontenerze Ubuntu.
	Uruchamiaj: po zmianach instalatora, aliasów, crona, generowania runtime.
3. `bash tests/run_docker_runtime_smoke_test.sh`
	Zakres: zachowanie runtime (backup/retention/logowanie/scenariusz braku konfiguracji NAS).
	Uruchamiaj: po zmianach logiki modułów runtime.
4. `bash tests/run_docker_all_modules_smoke_test.sh`
	Zakres: wszystkie wdrażane moduły runtime (pełna macierz PASS/WARN/FAIL).
	Uruchamiaj: przed wydaniem lub przy dużych refaktorach.
5. `bash tests/test_uninstaller_legacy_cleanup.sh`
	Zakres: czyszczenie legacy bloków v4.2.
	Uruchamiaj: po zmianach logiki uninstallera.

Zalecane minimum na co dzień:

```bash
bash tests/test_suite.sh
bash tests/run_docker_smoke_test.sh
```

Zalecany zestaw przed release:

```bash
bash tests/test_suite.sh
bash tests/run_docker_smoke_test.sh
bash tests/run_docker_runtime_smoke_test.sh
bash tests/run_docker_all_modules_smoke_test.sh
```

## 3. To samo przez Docker Compose

```bash
docker compose -f tests/docker/compose.yaml up --build --abort-on-container-exit
```

Sprzątanie po uruchomieniu:

```bash
docker compose -f tests/docker/compose.yaml down --remove-orphans
```

## 4. Ręczne budowanie i uruchamianie obrazu

Build:

```bash
docker build -t wsms-smoke-test -f tests/docker/Dockerfile .
```

Run:

```bash
docker run --rm wsms-smoke-test
```

Wejście do kontenera interaktywnie:

```bash
docker run --rm -it --entrypoint bash wsms-smoke-test
```

## 5. Najczęstsze problemy i szybkie poprawki

### Problem: No such file or directory

Najczęściej uruchamiasz komendę poza repo.

Naprawa:

```bash
cd /Users/lukaszmalec/Documents/Work_grup_space/wp-server-management-system
pwd
```

### Problem: Permission denied / Operation not permitted

Nie uruchamiaj testu na przypadkowych bind mountach poza projektem. Używaj gotowego wrappera:

```bash
bash tests/run_docker_smoke_test.sh
```

### Problem: Brak miejsca na dysku

```bash
docker system df
docker image prune -f
docker container prune -f
docker builder prune -f
```

## 6. Integracja z CI (GitHub Actions)

Workflow znajduje się w:

- `.github/workflows/ci.yml`

Uruchamia:

1. `bash tests/test_suite.sh`
2. build obrazu smoke test
3. uruchomienie smoke test w kontenerze

## 7. Co test jest w stanie sprawdzić

Tak:

- instalację WSMS,
- generowanie skryptów runtime,
- utworzenie katalogów i logów,
- konfigurację aliasów i crontaba,
- operacje oparte o strukturę plików WordPress.

Nie:

- realnej bazy danych MySQL,
- pełnego runtime WordPress z prawdziwym ruchem,
- testów wydajnościowych produkcyjnego środowiska.

## 8. Polecana codzienna sekwencja

```bash
cd /Users/lukaszmalec/Documents/Work_grup_space/wp-server-management-system
bash tests/test_suite.sh
bash tests/run_docker_smoke_test.sh
```

Jeśli oba kroki są zielone, masz wysoką pewność, że zmiany nie łamią instalatora.

Po zmianach w skryptach runtime uruchom dodatkowo:

```bash
bash tests/run_docker_runtime_smoke_test.sh
```

## 8.1 Szybkie drzewko decyzji (co zmieniłem -> co uruchomić)

1. Zmieniłem tylko dokumentację (`*.md`).

```bash
bash tests/test_suite.sh
```

2. Zmieniłem flow instalatora, aliasy, cron lub generowany layout.

```bash
bash tests/test_suite.sh
bash tests/run_docker_smoke_test.sh
```

3. Zmieniłem logikę modułów runtime (bloki deploy skryptów w `installers/*`).

```bash
bash tests/test_suite.sh
bash tests/run_docker_smoke_test.sh
bash tests/run_docker_runtime_smoke_test.sh
```

4. Zmieniłem wiele modułów lub przygotowuję release.

```bash
bash tests/test_suite.sh
bash tests/run_docker_smoke_test.sh
bash tests/run_docker_runtime_smoke_test.sh
bash tests/run_docker_all_modules_smoke_test.sh
```

5. Zmieniłem zachowanie uninstallera.

```bash
bash tests/test_uninstaller_legacy_cleanup.sh
bash tests/test_suite.sh
```

## 9. Procedura na dwa stanowiska (iMac biuro + MacBook zdalnie)

Stosuj ten sam schemat w każdym projekcie (WSMS, Python i inne):

1. Otwórz katalog projektu.
1. Zsynchronizuj projekt przez Git przed rozpoczęciem pracy:

```bash
git fetch --all --prune
git pull --ff-only
```

1. Uruchom lokalną walidację:

```bash
bash tests/test_suite.sh
bash tests/run_docker_smoke_test.sh
```

1. Commit i push rób dopiero po zielonych testach.
1. Sprawdź status CI na GitHub przed przejściem na drugie stanowisko.
1. Na drugim komputerze powtórz tę samą sekwencję przed dalszą pracą.

Praktyczna zasada: iCloud traktuj jako transport plików, a GitHub jako źródło prawdy i punkt awaryjnego odtworzenia repozytorium.

## 10. Szczegóły techniczne (jak działają testy Docker)

Przepływ wykonania:

1. Build obrazu z `tests/docker/Dockerfile` (`ubuntu:22.04`).
2. Skopiowanie repo do `/workspace` w obrazie.
3. Domyślny command kontenera uruchamia `tests/docker/run-install-smoke.sh`.
4. Wrappery runtime/all-modules nadpisują command i uruchamiają:
	 - `/workspace/tests/docker/run-runtime-behavior-smoke.sh`
	 - `/workspace/tests/docker/run-all-modules-smoke.sh`

Detale techniczne kontenera:

- Dockerfile ustawia retry/timeouts APT (`/etc/apt/apt.conf.d/99ci-retries`).
- tworzony jest użytkownik testowy `tester` z passwordless sudo.
- bezpieczna atrapa WordPress trafia do:
	- `/var/www/site1/public_html`
	- `/var/www/site2/public_html`
- instalator uruchamiany jest jako `tester` z katalogu `/home/tester/workspace`.

Przydatne zmienne środowiskowe wrapperów:

- `IMAGE_NAME` (domyślnie: `wsms-smoke-test`)
- `WSMS_DOCKER_KEEP_CONTAINER` (`1` zostawia kontener do debugowania)
- `WSMS_DOCKER_CONTAINER_NAME` (nazwa kontenera debugowego)

Artefakty i logi:

- raport all-modules: `/tmp/wsms-all-modules/report.txt`
- outputy per moduł: `/tmp/wsms-all-modules/*.out`
- logi runtime sprawdzane przez testy:
	- `~/logs/wsms/retention/retention.log`
	- `~/logs/wsms/sync/nas-sync.log`

Zachowanie kodów wyjścia:

- wrappery i smoke skrypty używają `set -euo pipefail`.
- każdy nieudany assert zwraca kod != 0 i failuje test.
- w all-modules: WARN nie failuje całego runa, FAIL failuje.
