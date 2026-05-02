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
