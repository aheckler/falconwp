# FalconWP

A shell script for creating local WordPress test sites.

## Requirements

* [Laravel Valet](https://laravel.com/docs/5.3/valet) (including `mariadb`)
* [WP-CLI](https://wp-cli.org/)
* The `jq` package from [Homebrew](http://brew.sh/)

## Installation

1. Clone the repo: `git clone https://github.com/aheckler/falconwp.git`
2. Make the script executable: `chmod +x falconwp.sh`
3. Use `brew services list` to ensure that `php70`, `mariadb`, and `dnsmasq` are running.
4. Park a directory in Valet. I usually do `valet park ~/Sites`.

## Usage

1. Run `sh falconwp.sh sitename`, where `sitename` is an alphanumeric string.
2. FalconWP will spin up a local WordPress site and open it in your browser.
3. The WordPress admin credentials will be output in Terminal.

**Note:** FalconWP will create sites in the first path listed in `~/.valet/config.json`.
