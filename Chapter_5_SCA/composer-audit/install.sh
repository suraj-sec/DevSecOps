apt update && apt install -y php7.4 php7.4-gd php7.4-intl php7.4-xsl php7.4-mbstring
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
php -r "unlink('composer-setup.php');"
composer install
composer audit


