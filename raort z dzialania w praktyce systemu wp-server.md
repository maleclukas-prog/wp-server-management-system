Rozumiem. Oto **notatka w formacie Markdown**, którą możesz przekazać innemu agentowi (np. AI odpowiedzialnemu za dokumentację). Zawiera ona:

- **Co się wydarzyło** – opis problemu z `photographerwithawalker.com`
- **Co zrobiliśmy** – kroki diagnostyczne i naprawcze
- **Jak system naprawił uprawnienia** – szczegółowy opis działania `http200-fix` i `wp-fix-perms`
- **Polecenie do agenta** – co ma dodać, gdzie i w jakiej formie

---

## 📄 Notatka do agenta dokumentacji

```markdown
# Notatka techniczna – przypadek `photographerwithawalker.com`

## 📌 Cel notatki

Niniejsza notatka ma zostać wykorzystana przez agenta odpowiedzialnego za dokumentację techniczną systemu WSMS PRO. Należy ją dodać do istniejących plików dokumentacji (`README.md`, `CASE-STUDIES.md`, `TROUBLESHOOTING.md`) oraz ewentualnie do opisu projektu w CV.

---

## 🔍 Opis problemu

Po przywróceniu VPS z snapshotu (przygotowanego 2 dni wcześniej) strona `photographerwithawalker.com` przestała być dostępna. Serwer WWW (Nginx) zwracał kod HTTP 404 dla tej domeny, podczas gdy pozostałe 5 stron działały poprawnie.

**Cel:** Przywrócenie działania strony bez ręcznej ingerencji w pliki konfiguracyjne, z wykorzystaniem narzędzi systemu WSMS PRO.

---

## 🛠️ Przebieg diagnostyki i naprawy

### 1. Sprawdzenie dostępności wszystkich stron

Wykonano polecenie:

```bash
for site in photographerwithawalker polskieokna mindreflection superphotocam wedzarniczebractwo whiteeaglesmokehouse; do
    curl -I https://$site.com 2>/dev/null | head -1
done
```

**Wynik:**
Wszystkie strony zwróciły kod 200 lub 301 (poprawne przekierowanie). Wyjątek: `photographerwithawalker.com` → **HTTP 404**.

### 2. Test WP-CLI (`wp-cli-validator`)

```bash
wp-cli-validator
```

**Wynik:**
Wszystkie 6 stron przeszło test WP-CLI – potwierdzenie, że WordPress, PHP i bazy danych działają poprawnie. Problem leży po stronie serwera WWW.

### 3. Naprawa uprawnień (`http200-fix`)

```bash
http200-fix
```

**Wynik:**
Narzędzie zgłosiło naprawę uprawnień dla `photographerwithawalker.com`:

```
✅ wp-config.php secured (640)
✅ ACL set for user lukasz
✅ photographerwithawalker.com permissions fixed
```

Jednak strona nadal zwracała HTTP 404 – uprawnienia nie były jedyną przyczyną problemu.

### 4. Ręczna weryfikacja konfiguracji Nginx

Sprawdzenie struktury plików:

```bash
ls -la /etc/nginx/sites-available/
ls -la /etc/nginx/sites-enabled/
```

**Wynik:**
Wszystkie strony są skonfigurowane w jednym pliku `wordpress-sites`, który jest poprawnie włączony.

Weryfikacja wpisu dla `photographerwithawalker.com`:

```bash
sudo cat /etc/nginx/sites-available/wordpress-sites | grep -A 10 "photographerwithawalker"
```

**Wynik:**
Konfiguracja istnieje i jest poprawna. Sekcja zawiera prawidłowe ustawienia `server_name`, `root`, `ssl_certificate` itp.

### 5. Przeładowanie Nginx

```bash
sudo systemctl reload nginx
```

**Wynik:**
Przeładowanie przebiegło bez błędów. Usługa Nginx została odświeżona bez przerywania pracy innych stron.

### 6. Końcowe sprawdzenie

```bash
curl -I https://photographerwithawalker.com
```

**Wynik:**

```
HTTP/1.1 301 Moved Permanently
Location: https://www.photographerwithawalker.com/
```

Strona została przywrócona i działa poprawnie.

---

## 🧠 Jak system naprawił uprawnienia?

System WSMS PRO wykorzystuje mechanizm ACL (Access Control Lists) do zarządzania uprawnieniami. Każda strona ma dedykowanego użytkownika (np. `wordpress_photo`) oraz grupę.

### `http200-fix` wykonał:

1. **Zabezpieczenie `wp-config.php`** – ustawienie uprawnień `640`, aby plik był czytelny tylko dla właściciela i grupy.
2. **Dodanie ACL dla użytkownika `lukasz`** – umożliwienie dostępu do plików strony bez zmiany właściciela.
3. **Naprawę uprawnień dla całej strony** – przywrócenie domyślnych uprawnień dla katalogów (`755`) i plików (`644`).

Dzięki temu system zachowuje bezpieczeństwo (izolacja użytkowników) i jednocześnie umożliwia wygodną pracę administratorowi.

---

## 📋 Podsumowanie

| Etap                   | Narzędzie / Komenda            | Wynik                                       |
| ---------------------- | ------------------------------- | ------------------------------------------- |
| Wykrycie problemu      | `wp-status` / `curl`        | HTTP 404 dla`photographerwithawalker.com` |
| Test WP-CLI            | `wp-cli-validator`            | ✅ Wszystkie strony OK                      |
| Naprawa uprawnień     | `http200-fix`                 | ✅ ACL i`wp-config.php` naprawione        |
| Weryfikacja Nginx      | `sudo nginx -T`               | ✅ Konfiguracja poprawna                    |
| Przeładowanie Nginx   | `sudo systemctl reload nginx` | ✅ Usługa odświeżona                     |
| Ostateczne sprawdzenie | `curl -I https://...`         | ✅ HTTP 301 – strona działa               |

---

## 📂 Gdzie dodać tę notatkę?

Proszę o dodanie tej notatki do następujących plików dokumentacji:

1. **`README.md`** – w sekcji "Przykład działania" lub "Case Studies".
2. **`CASE-STUDIES.md`** – jako osobny rozdział: "Przywracanie strony po snapshotcie".
3. **`TROUBLESHOOTING.md`** – w sekcji "HTTP 404 – strona nie działa po przywróceniu z backupu".
4. **`CHANGELOG.md`** – jako wpis o ulepszeniu narzędzi diagnostycznych.

Dodatkowo można umieścić skróconą wersję w opisie projektu w CV autora (Lukasz Malec).

---

## 🔗 Powiązane narzędzia WSMS PRO

- `wp-status` – przegląd stanu wszystkich stron
- `wp-cli-validator` – test łączności WP-CLI
- `wp-fix-perms` – naprawa uprawnień i ACL
- `http200-fix` – diagnostyka i naprawa HTTP 404/500
- `wp-snapshot` / `wp-rollback` – zarządzanie snapshotami

---

## 👤 Autor

Lukasz Malec
Projekt: WSMS PRO v4.4
Data: 12.07.2026

```

---

## 📋 Instrukcja dla agenta

Przekaż powyższą notatkę agentowi dokumentacji z następującym poleceniem:

> **Polecenie:**  
> Dodaj powyższą notatkę do plików `README.md`, `CASE-STUDIES.md` i `TROUBLESHOOTING.md` w repozytorium WSMS PRO. Dostosuj formatowanie do istniejącej struktury dokumentacji. Jeśli pliki nie istnieją – utwórz je. Zachowaj nagłówki, listy i bloki kodu w identycznej formie.

Gotowe! 🚀
```
