# FalconWP

A shell script for creating local WordPress test sites.

## Requirements

* [Laravel Valet](https://laravel.com/docs/5.8/valet) (including `mariadb`)
* [WP-CLI](https://wp-cli.org/)
* The `jq` package from [Homebrew](http://brew.sh/)

## Installation

1. Clone the repo: `git clone https://github.com/aheckler/falconwp.git`
2. Make the script executable: `chmod +x falconwp.sh`
3. Use `brew services list` to ensure that `dnsmasq`, `mariadb`, `nginx`, and `php` are running.
4. Optionally, set your MariaDB root password to the evironment variable `MARIADB_ROOT_PW`.
5. Park a directory in Valet. I usually do `valet park ~/Sites`.

## Usage

1. Run `sh falconwp.sh`.
2. Enter the root password for MariaDB if prompted.
3. FalconWP will spin up a local WordPress site and open it in your browser.
4. The WordPress admin credentials will be output in Terminal.

**Note:** FalconWP will create sites in the first path listed in `~/.valet/config.json`.
