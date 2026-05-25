# Instalação no Plesk

Este repositório foi preparado para `Plesk Obsidian` com `Roundcube` instalado em `/usr/share/psa-roundcube`.

## Objetivo

Instalar:

- `automatic_addressbook`
- `libcalendaring`
- `libkolab`
- `calendar`

sem editar o `composer.json` principal do `Roundcube` do `Plesk` e sem repetir o fluxo antigo baseado em `PHP 7.0`, `Node 10` ou `echo >> config.inc.php`.

## Pré-requisitos

- `Plesk Obsidian` com `Roundcube` funcional
- acesso root ou `sudo`
- `php` CLI
- `mysql` CLI
- acesso de leitura a `/etc/psa/.psa.shadow`
- opcional: `lessc` para recompilar `libkolab.css`

## Comando recomendado

```bash
sudo ./installer/install-plesk.sh \
  --target-dir /usr/share/psa-roundcube \
  --db-name roundcubemail \
  --calendar-driver database
```

## Modos suportados

Instalar só o auto-coletor:

```bash
sudo ./installer/install-plesk.sh --install-set automatic
```

Instalar só o stack de calendário:

```bash
sudo ./installer/install-plesk.sh \
  --install-set calendar \
  --calendar-driver kolab
```

## O que o instalador faz

1. copia os plugins do monorepo para `plugins/`
2. cria backups do que já existia
3. instala um fragmento gerenciado em `config/callendar.plugins.inc.php`
4. adiciona um `include` seguro em `config/config.inc.php`
5. copia templates de configuração dos plugins sem sobrescrever customizações existentes, exceto com `--force-config`
6. recompila ou materializa os assets `Elastic`
7. importa os SQL iniciais necessários

## SQL aplicado por backend

Sempre:

- `plugins/automatic_addressbook/SQL/mysql.initial.sql` quando `automatic_addressbook` estiver selecionado
- `plugins/libkolab/SQL/mysql.initial.sql` quando o stack de calendário estiver selecionado

Backend do calendário:

- `database`: `plugins/calendar/drivers/database/SQL/mysql.initial.sql`
- `kolab`: `plugins/calendar/drivers/kolab/SQL/mysql.initial.sql`
- `caldav`: `plugins/calendar/drivers/caldav/SQL/mysql.initial.sql`

## Arquivos de configuração gerenciados

- `/usr/share/psa-roundcube/config/callendar.plugins.inc.php`
- `/usr/share/psa-roundcube/plugins/automatic_addressbook/config/config.inc.php`
- `/usr/share/psa-roundcube/plugins/calendar/config/config.inc.php`
- `/usr/share/psa-roundcube/plugins/libkolab/config.inc.php`

## Assets Elastic

O script `installer/build-elastic-assets.sh`:

- recompila `libkolab.less` em `libkolab.css` quando `lessc` está disponível
- usa fallback do skin `larry` quando o asset `elastic` está ausente
- garante a presença de:
  - `libkolab.css`
  - `libcal.css`
  - `fullcalendar.css`
  - `calendar.css`
  - `print.css`

## Rollback

Para restaurar o último backup do target:

```bash
sudo ./installer/rollback.sh --target-dir /usr/share/psa-roundcube
```

Para restaurar um manifesto específico:

```bash
sudo ./installer/rollback.sh \
  --target-dir /usr/share/psa-roundcube \
  --manifest /caminho/para/manifest.tsv
```
