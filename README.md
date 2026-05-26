# Roundcube Plugin Port for Plesk

Este projeto é uma adaptação modernizada do plugin `automatic_addressbook` e da parte de calendário do stack `roundcubemail-plugins-kolab`, preparada para uso prático em `Roundcube 1.6+` no `Plesk Obsidian`.

A proposta não é reescrever esses projetos do zero, e sim empacotar os upstreams com os ajustes necessários para ambientes atuais: compatibilidade com `PHP 8.3+`, instalação manual segura, SQL por backend, assets `Elastic` já presentes, backup, rollback e reexecução idempotente.

Do stack `Kolab`, este repositório usa especificamente `calendar`, `libcalendaring` e `libkolab`: a mesma parte que, em uma instalação manual, você normalmente clonaria do upstream e copiaria para `plugins/`, seguido da criação do `config.inc.php` a partir de `config.inc.php.dist`. Aqui, esse fluxo foi transformado em uma instalação mais prática e repetível para `Plesk`.

## O que este repositório entrega

- `upstream/`: cópias importadas dos plugins originais, já com patches mínimos aplicados
- `installer/`: instalador idempotente, build de assets e rollback
- `docs/`: instalação, migração do método legado e manutenção do monorepo
- `smoke-tests/`: verificações rápidas de sintaxe, layout e assets
- `patches/`: inventário das alterações feitas sobre os upstreams

## Baseline importada

- `automatic_addressbook`: tag `0.4.3`, commit `ca622de3364b996c655eea2e7724ce6e325e9b9d`
- `roundcubemail-plugins-kolab`: tag `roundcubemail-plugins-kolab-3.6.1`, commit `ca804db0a37dec164595d26574bb38802ee725aa`

## Principais ajustes aplicados

- `automatic_addressbook`
  - guards para `PHP 8.x`
  - remoção de carregamento de config por path frágil
  - backend respeitando `db_table_collected_contacts`
  - `composer.json` e `INSTALL` atualizados para `Roundcube 1.6+`

- stack `Kolab`
  - atualização do requisito mínimo de `roundcube/plugin-installer`
  - fallback de CSS para instalações manuais no `Plesk`
  - assets `Elastic` materializados no monorepo
  - `README` do calendário ajustado para SQL por backend

## Uso rápido

Baixar o repositório e testar no `Plesk`:

```bash
git clone https://github.com/sergioopenweb/roundcube-plesk-plugin-port.git
cd roundcube-plesk-plugin-port

./installer/preflight-plesk.sh \
  --target-dir /usr/share/psa-roundcube \
  --db-name roundcubemail \
  --calendar-driver database

./installer/install-plesk.sh \
  --target-dir /usr/share/psa-roundcube \
  --db-name roundcubemail \
  --calendar-driver database
```

Se o banco já tiver as tabelas desses plugins, o instalador tenta detectar isso e marca o SQL como já aplicado automaticamente.

Se você já usa `root` no `AlmaLinux`, não precisa de `sudo`.

Se preferir baixar como arquivo compactado em vez de usar `git clone`:

```bash
curl -L -o roundcube-plesk-plugin-port.tar.gz \
  https://github.com/sergioopenweb/roundcube-plesk-plugin-port/archive/refs/heads/main.tar.gz
tar -xzf roundcube-plesk-plugin-port.tar.gz
cd roundcube-plesk-plugin-port-main

./installer/preflight-plesk.sh \
  --target-dir /usr/share/psa-roundcube \
  --db-name roundcubemail \
  --calendar-driver database

./installer/install-plesk.sh \
  --target-dir /usr/share/psa-roundcube \
  --db-name roundcubemail \
  --calendar-driver database
```

Rollback:

```bash
./installer/rollback.sh --target-dir /usr/share/psa-roundcube
```

Smoke tests locais:

```bash
./smoke-tests/php-lint.sh
./smoke-tests/verify-layout.sh
./smoke-tests/verify-elastic-assets.sh
```

## Documentação

- [Instalação no Plesk](docs/install-plesk.md)
- [Migração do método legado](docs/upgrade-from-legacy.md)
- [Notas de manutenção](docs/developer-notes.md)
