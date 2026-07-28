# Tworzenie środowiska testowego serwera (Docker, etap 1)

## Status dokumentu

Ten dokument opisuje eksperymentalny workflow odwzorowania serwera z backupu.
Nie jest to glowna, kanoniczna sciezka testowa repozytorium.

Preferowana sciezka testow (utrzymywana na biezaco):

- `bash tests/run_docker_smoke_test.sh`
- `bash tests/run_docker_runtime_smoke_test.sh`
- `bash tests/run_docker_all_modules_smoke_test.sh`
- `bash tests/run_docker_notify_smoke_test.sh`

Ten dokument opisuje bezpieczny i praktyczny proces odwzorowania serwera do testów WSMS.

Cel na teraz: stabilne środowisko testowe w Dockerze.
Kubernetes: opcjonalny etap 2, dopiero po potwierdzeniu działania w Dockerze.

## Założenia

1. Nie ruszamy produkcji.
2. Nie commitujemy wrażliwych danych.
3. Najpierw uruchamiamy "kopię serwera" lokalnie, potem testujemy WSMS.
4. Dla retencji/NAS testujemy logikę etapowo i powtarzalnie.

## Co już masz

- Katalog backupu serwera: `server_backup/`
- Możliwy wariant archiwum: `server_backup.tar.gz`

## Bezpieczeństwo danych (obowiązkowe)

Przed jakimkolwiek push do repo:

1. Sprawdź `git status`.
2. Upewnij się, że backup serwera i archiwa są ignorowane przez `.gitignore`.
3. Nigdy nie commituj:
     - kluczy prywatnych,
     - haseł,
     - tokenów,
     - pełnych dumpów produkcyjnych z danymi klientów.

## Wymagania lokalne

- Docker Desktop
- `rsync` 3.2+ (jeśli pobierasz nowy backup z serwera)
- Wolne miejsce na dysku (minimum rozmiar backupu + zapas)

## Etap 1: Docker (rekomendowany start)

### Krok 1. Przygotowanie źródła obrazu

Masz dwie opcje:

1. Użyć już istniejącego `server_backup/`.
2. Użyć `server_backup.tar.gz`.

Jeśli masz tylko katalog i chcesz zrobić archiwum:

```bash
cd "experimental/Tworzenie srodowiska docker/server_backup"
sudo tar -cvpzf ../server_backup.tar.gz \
    --exclude=./proc --exclude=./sys --exclude=./dev \
    --exclude=./tmp --exclude=./run --exclude=./mnt \
    --exclude=./media --exclude=./lost+found .
```

### Krok 2. Import do Dockera

```bash
docker import "experimental/Tworzenie srodowiska docker/server_backup.tar.gz" wsms-server:test
docker images | grep wsms-server
```

### Krok 3. Start kontenera

```bash
docker run -it --name wsms-server-test wsms-server:test /bin/bash
```

W środku kontenera sprawdź minimum:

```bash
cat /etc/os-release
ls -la /var/www
ls -la /home
```

### Krok 4. Uruchamianie usług (bez systemd)

W kontenerze zwykle nie działa pełny `systemd`, więc uruchamiaj usługi ręcznie.

Przykład:

```bash
service nginx start || true
service mysql start || true
service php8.4-fpm start || true
```

## Etap 1b: Testy WSMS w kopii serwera

Po uruchomieniu środowiska testuj kluczowe ścieżki:

1. Backupy (`lite/full/mysql`)
2. Retencja (`backup-clean`, `backup-force-clean`)
3. NAS sync (`nas-sync`, logi)
4. Logika awaryjna przy niskim miejscu

Minimalna checklista:

```bash
wp-help
backup-size
backup-clean
nas-sync
nas-sync-status
```

## Potwierdzenie synchronizacji (NAS/server backup target)

Do potwierdzenia, że plik naprawdę został wysłany:

1. Utwórz nowy plik testowy lokalnie.
2. Uruchom `nas-sync`.
3. Sprawdź w podsumowaniu `Uploaded > 0`.
4. Sprawdź log (`nas-sync-status`, `nas-sync-logs`).
5. Sprawdź obecność pliku po stronie zdalnej.

## Etap 2: Kubernetes (dopiero po Docker)

Kubernetes ma sens, gdy:

1. Dockerowe testy są stabilne.
2. Wiesz, które usługi wydzielasz osobno (www, db, backup, sync).
3. Masz gotowe healthchecki i politykę danych.

Na ten moment nie rekomenduje się startu od K8s dla pełnego obrazu rootfs.

## Plan prac (krótko)

1. Ustabilizować środowisko Docker.
2. Zweryfikować retencję i synchronizację NAS.
3. Dodać automatyczne scenariusze testowe.
4. Dopiero potem projekt K8s.

## Szybkie komendy operacyjne

Start kontenera:

```bash
docker run -it --name wsms-server-test wsms-server:test /bin/bash
```

Ponowny start istniejącego kontenera:

```bash
docker start -ai wsms-server-test
```

Usunięcie kontenera testowego:

```bash
docker rm -f wsms-server-test
```

Usunięcie obrazu testowego:

```bash
docker rmi wsms-server:test
```

## Definicja sukcesu etapu 1

Uznajemy etap za gotowy, gdy:

1. Obraz startuje powtarzalnie.
2. Kluczowe usługi uruchamiają się ręcznie.
3. WSMS backup/retention/sync działa w scenariuszach testowych.
4. Logi potwierdzają operacje wysyłki i czyszczenia.
