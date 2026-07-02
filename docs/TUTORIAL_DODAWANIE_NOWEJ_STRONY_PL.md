# Tutorial: Dodawanie kolejnej strony WordPress na Twoim serwerze (Nginx + PHP-FPM per user + MySQL)

Ten tutorial jest przygotowany pod Twoj aktualny model serwera:

- Ubuntu
- Nginx (u Ciebie konfiguracja jest w jednym pliku, np. /etc/nginx/sites-enabled/wordpress-sites)
- PHP 8.4 FPM, osobny socket per strona/uzytkownik
- WordPress w /var/www/NAZWA_DOMENY/public_html
- Backupy SQL w /home/ubuntu/Dokumenty/d3thecamels/MsQl
- WSMS do walidacji (wp-cli-validator, wp-fleet)

Cel: dodac kolejna gotowa strone poprawnie i powtarzalnie, bez zgadywania.

## 1. Zmienne startowe (uzupelnij raz)

Przyklad (podmien wartosci):

DOMAIN="anitahoppephotography.com"
WWW_DOMAIN="www.anitahoppephotography.com"
SITE_USER="anitahoppephotography"
SITE_ROOT="/var/www/anitahoppephotography.com/public_html"
PHP_VER="8.4"
PHP_POOL="/etc/php/8.4/fpm/pool.d/anitahoppephotography.comf"
PHP_SOCK="/run/php/php8.4-fpm-anitahoppephotography.com.sock"
DB_NAME="anitahoppephotography.com_db"
DB_USER="anitahoppephotography.com"
DB_PASS="ksj*ue)js-&sns"
SQL_DUMP="/home/ubuntu/Dokumenty/d3thecamels/MsQl/plik.sql"

## 2. Precheck (zanim cokolwiek zmienisz)

Sprawdz czy katalog strony istnieje:

ls -la /var/www/anitahoppephotography.com/public_html

Sprawdz czy jest WordPress:

ls -la /var/www/anitahoppephotography.com/public_html | head -20

Sprawdz czy SQL dump istnieje (jesli importujesz gotowa baze):

ls -la /home/ubuntu/Dokumenty/d3thecamels/MsQl

## 3. Uzytkownik systemowy i katalog domowy

Jesli user nie istnieje:

sudo useradd -m -d /home/anitahoppephotography.com -s /usr/sbin/nologin anitahoppephotography.com

Przygotuj cache WP-CLI:

sudo install -d -m 755 -o anitahoppephotography.com -g anitahoppephotography.com /home/anitahoppephotography.com/.wp-cli/cache

## 4. Uprawnienia plikow strony

sudo chown -R nowadomena:nowadomena /var/www/anitahoppephotography.com
sudo find /var/www/anitahoppephotography.com -type d -exec chmod 755 {} \;
sudo find /var/www/anitahoppephotography.com -type f -exec chmod 644 {} \;
sudo chmod 640 /var/www/anitahoppephotography.com/public_html/wp-config.php 2>/dev/null || true

## 5. PHP-FPM pool (osobny socket)

Utworz plik pool:

sudo tee /etc/php/8.4/fpm/pool.d/anitahoppephotography.com.conf > /dev/null << 'EOF'
[anitahoppephotography.com]
user = anitahoppephotography.com
group = anitahoppephotography.com
listen = /run/php/php8.4-fpm-anitahoppephotography.com.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3

php_admin_value[disable_functions] = exec,passthru,shell_exec,system
php_admin_flag[allow_url_fopen] = off
EOF

Walidacja i reload:

sudo php-fpm8.4 -t
sudo systemctl reload php8.4-fpm
ls -la /run/php/php8.4-fpm-anitahoppephotography.com.sock

## 6. Nginx: dodanie/edytowanie bloku domeny

Wazne: fastcgi_pass to NIE komenda shell. To linia do pliku Nginx.

W bloku server dla domeny ustaw:

root /var/www/anitahoppephotography.com/public_html;

location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/php8.4-fpm-anitahoppephotography.com.sock;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;
}

Po edycji:

sudo nginx -t
sudo systemctl reload nginx

## 7. MySQL: baza i user (koniecznie jako root MySQL)

Wejdz do MySQL:

sudo mysql -u root -p

W srodku mysql> wykonaj:

CREATE DATABASE anitahoppephotography.com_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'anitahoppephotography.com'@'localhost' IDENTIFIED BY 'TU_USTAW_MOCNE_HASLO';
GRANT ALL PRIVILEGES ON anitahoppephotography.com_db.* TO 'anitahoppephotography.com'@'localhost';
FLUSH PRIVILEGES;
exit

## 8. Import SQL (najbezpieczniej z shell, nie z mysql prompt)

Poprawny import:

mysql -u root -p nowadomena_db < /home/ubuntu/Dokumenty/d3thecamels/MsQl/plik.sql

Albo z sudo:

sudo mysql -u root -p nowadomena_db < /home/ubuntu/Dokumenty/d3thecamels/MsQl/plik.sql

Szybka kontrola tabel:

mysql -u root -p -e "SHOW TABLES FROM nowadomena_db;" | head -20

## 9. Aktualizacja wp-config.php

Najpierw backup:

sudo cp /var/www/nowadomena.pl/public_html/wp-config.php /var/www/nowadomena.pl/public_html/wp-config.php.bak.$(date +%Y%m%d-%H%M%S)

Potem podmiana DB_*:

sudo sed -i "s/define( *'DB_NAME'.*/define( 'DB_NAME', 'nowadomena_db' );/" /var/www/nowadomena.pl/public_html/wp-config.php
sudo sed -i "s/define( *'DB_USER'.*/define( 'DB_USER', 'nowadomena' );/" /var/www/nowadomena.pl/public_html/wp-config.php
sudo sed -i "s/define( *'DB_PASSWORD'.*/define( 'DB_PASSWORD', 'TU_USTAW_MOCNE_HASLO' );/" /var/www/nowadomena.pl/public_html/wp-config.php
sudo sed -i "s/define( *'DB_HOST'.*/define( 'DB_HOST', 'localhost' );/" /var/www/nowadomena.pl/public_html/wp-config.php

## 10. WP-CLI test strony

sudo -u nowadomena wp --path=/var/www/nowadomena.pl/public_html core version
sudo -u nowadomena wp --path=/var/www/nowadomena.pl/public_html option get home

Jesli po migracji domeny/URL sa stare:

sudo -u nowadomena wp --path=/var/www/nowadomena.pl/public_html search-replace "stara-domena.pl" "nowadomena.pl" --skip-columns=guid --all-tables

## 11. DNS i SSL (na koncu)

Dopiero gdy DNS wskazuje na ten serwer:

sudo certbot --nginx -d nowadomena.pl -d www\.nowadomena.pl

## 12. MySQL: zmiana slabego hasla (rotacja hasel)

Jesli hasla DB sa zbyt proste, zmien je od razu po migracji.

1. Wygeneruj mocne hasla lokalnie (przyklad):

openssl rand -base64 24

1. Zmien haslo usera DB w MySQL (jako root MySQL):

sudo mysql -u root -p

W mysql>:

ALTER USER 'nowadomena'@'localhost' IDENTIFIED BY 'NOWE_BARDZO_MOCNE_HASLO';
FLUSH PRIVILEGES;
exit

1. Zmien haslo w wp-config.php tej strony:

sudo sed -i "s/define( *'DB_PASSWORD'.*/define( 'DB_PASSWORD', 'NOWE_BARDZO_MOCNE_HASLO' );/" /var/www/nowadomena.pl/public_html/wp-config.php

1. Ustaw bezpieczne uprawnienia na wp-config.php:

sudo chmod 640 /var/www/nowadomena.pl/public_html/wp-config.php
sudo chown nowadomena:nowadomena /var/www/nowadomena.pl/public_html/wp-config.php

1. Szybki test po zmianie hasla:

sudo -u nowadomena wp --path=/var/www/nowadomena.pl/public_html db check
sudo -u nowadomena wp --path=/var/www/nowadomena.pl/public_html option get home

Rotacja hurtowa dla wielu stron (przyklad):

sudo mysql -u root -p << 'EOF'
ALTER USER 'mindreflection'@'localhost' IDENTIFIED BY 'TU_MOCNE_HASLO_1';
ALTER USER 'polskieokna'@'localhost' IDENTIFIED BY 'TU_MOCNE_HASLO_2';
ALTER USER 'superphotocam'@'localhost' IDENTIFIED BY 'TU_MOCNE_HASLO_3';
ALTER USER 'wedzarnicze'@'localhost' IDENTIFIED BY 'TU_MOCNE_HASLO_4';
ALTER USER 'whiteeagle'@'localhost' IDENTIFIED BY 'TU_MOCNE_HASLO_5';
FLUSH PRIVILEGES;
EOF

Po tym musisz zaktualizowac hasla DB_PASSWORD w odpowiednich wp-config.php.

## 13. Walidacja koncowa

sudo nginx -t && systemctl is-active nginx
sudo php-fpm8.4 -t && systemctl is-active php8.4-fpm
wp-cli-validator
wp-fleet

## 14. Integracja z WSMS (zeby widzialo nowa strone)

Upewnij sie, ze nowa domena jest w SITES w ~/scripts/wsms-config.sh w formacie:

nowadomena.pl:/var/www/nowadomena.pl/public_html:nowadomena

Potem:

source ~/scripts/wsms-config.sh
wp-cli-validator
wp-fleet

## Najczestsze bledy i szybkie naprawy

1) fastcgi_pass: command not found
   Przyczyna: wpisane w shell zamiast do pliku Nginx.
   Naprawa: edytuj config Nginx, potem nginx -t i reload.
2) Access denied dla CREATE DATABASE / CREATE USER
   Przyczyna: logowanie do MySQL jako user WP, nie root.
   Naprawa: sudo mysql -u root -p
3) ERROR 1046 No database selected podczas SOURCE
   Przyczyna: SOURCE odpalony bez USE db albo zly sposob importu.
   Naprawa: import z shell: mysql -u root -p NAZWA_BAZY < plik.sql
4) SOURCE ~/... szuka /root/...
   Przyczyna: w mysql przy sudo i ~ rozwija sie inaczej.
   Naprawa: zawsze uzywaj pelnej sciezki, np. /home/ubuntu/...
5) Wpisanie komendy shell wewnatrz mysql>
   Przyczyna: pomylone konteksty.
   Naprawa: wyjdz z mysql przez exit i uruchom komende w shell.
6) Access denied (1044/1227) przy CREATE DATABASE/CREATE USER/GRANT
   Przyczyna: zalogowanie do MySQL jako user WordPress (np. z wp-config.php), a nie admin/root MySQL.
   Naprawa: wyjdz z mysql i zaloguj sie jako root MySQL: sudo mysql -u root -p
7) Import SQL nie dziala po SOURCE ~/... albo po wklejeniu sudo mysql ... wewnatrz mysql>
   Przyczyna: (a) SOURCE z ~ pod sudo wskazuje na /root, (b) komendy shell zostaly uruchomione w mysql>.
   Naprawa:
   - W mysql> uzywaj SOURCE tylko z pelna sciezka, np. SOURCE /home/ubuntu/Dokumenty/d3thecamels/MsQl/plik.sql;
   - Komendy typu sudo mysql baza < plik.sql uruchamiaj w shell, nie w mysql>.

## Problem z rana i rozwiazanie (praktyczny przypadek)

Problem:
- Logowanie do MySQL userem z wp-config.php (np. mindrefl_xiwg1) powodowalo bledy:
  - ERROR 1044 Access denied przy CREATE DATABASE i GRANT
  - ERROR 1227 Access denied przy CREATE USER i FLUSH PRIVILEGES
- Import nie dzialal, bo:
  - komendy shell zostaly wklejone do mysql>
  - SOURCE ~/... probowal czytac pliki z /root/... zamiast /home/ubuntu/...

Rozwiazanie:
1. Wyjsc z mysql przez exit.
2. Zalogowac sie jako root MySQL: sudo mysql -u root -p
3. Utworzyc bazy i userow dopiero z konta root.
4. Importowac SQL jedna z dwoch poprawnych metod:
   - w shell: sudo mysql -u root -p NAZWA_BAZY < /home/ubuntu/Dokumenty/d3thecamels/MsQl/plik.sql
   - w mysql>: SOURCE /home/ubuntu/Dokumenty/d3thecamels/MsQl/plik.sql;
5. Po imporcie sprawdzic tabele: SHOW TABLES FROM nazwa_bazy;

Szybki test poprawnosci:
- readlink -f ~/Dokumenty/d3thecamels/MsQl/
- powinno zwrocic: /home/ubuntu/Dokumenty/d3thecamels/MsQl
- tej sciezki uzywaj w SOURCE.

## Mini-checklista (skroc)

- User Linux utworzony i ma /home/user/.wp-cli/cache
- Wlasnosc plikow: user:user
- Pool PHP-FPM utworzony i socket istnieje
- Nginx blok ma poprawny fastcgi_pass do nowego socketu
- DB i DB user utworzone jako root MySQL
- SQL zaimportowany do poprawnej bazy
- wp-config.php ma nowe DB_* dane
- WP-CLI dziala jako user strony
- Nginx i php-fpm aktywne
- SITES zaktualizowane, wp-fleet i wp-cli-validator zielone
