# Migração do método legado

O procedimento antigo misturava:

- cópia manual em `/usr/share/psa-roundcube/plugins`
- edição direta de `/usr/share/psa-roundcube/composer.json`
- uso de `/opt/plesk/php/7.0/bin/php`
- `Node 10`
- `echo '$rcmail_config[...]' >> config.inc.php`

Esse fluxo não é adequado para `Plesk Obsidian 18` com `Roundcube 1.6+`.

## O que mudou neste monorepo

### Antes

- tutorial pensado para `Roundcube 0.x/1.0`
- instruções referenciando `main.inc.php`
- dependências Composer antigas
- CSS `Elastic` incompleto
- SQL tratado como passo único mesmo para backends diferentes

### Agora

- `automatic_addressbook` endurecido para `PHP 8.x`
- stack `Kolab` ajustado para `Roundcube 1.6+`
- instalação centralizada em `installer/install-plesk.sh`
- rollback com manifesto
- configs aplicadas por templates controlados no repositório
- fragmento separado para habilitar plugins no `Roundcube`

## Substituições práticas

### Em vez de editar o `composer.json` principal do Plesk

Não faça isso.

Use:

```bash
./installer/install-plesk.sh
```

Se você estiver logado como `root`, não precisa de `sudo`.

### Em vez de usar `PHP 7.0`

Use o `php` CLI atual do sistema/Plesk.

### Em vez de `Node 10`

Use `lessc` atual, se disponível. Se não estiver disponível, o instalador usa os fallbacks CSS incluídos no monorepo.

### Em vez de anexar plugin no config com `echo >>`

O instalador cria `config/callendar.plugins.inc.php` e injeta um `include` idempotente em `config/config.inc.php`.

## Cuidados na migração

- faça backup antes de substituir uma instalação manual antiga
- se já houver tabelas do plugin no banco, avalie usar `--skip-sql`
- se você já tiver configs locais customizadas dos plugins, rode sem `--force-config`
- se já houver customização manual nos diretórios de plugin, o rollback depende dos backups criados pelo instalador deste monorepo
