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

Co robi ten test:

- buduje obraz z `tests/docker/Dockerfile`,
- przygotowuje bezpieczną atrapę WP z `tests/fixtures/wordpress/public_html`,
- uruchamia `installers/install_wsms.sh`,
- weryfikuje podstawowe artefakty instalacji (skrypty, aliasy, crontab).

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