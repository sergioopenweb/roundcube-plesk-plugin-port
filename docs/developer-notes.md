# Notas de manutenção

## Upstreams usados

### automatic_addressbook

- repositório: `https://github.com/sblaisot/automatic_addressbook.git`
- ref importada: `0.4.3`
- commit: `ca622de3364b996c655eea2e7724ce6e325e9b9d`

### Kolab plugins

- repositório: `https://git.kolab.org/diffusion/RPK/roundcubemail-plugins-kolab.git`
- ref importada: `roundcubemail-plugins-kolab-3.6.1`
- commit: `ca804db0a37dec164595d26574bb38802ee725aa`

## Estrutura do monorepo

- `upstream/automatic_addressbook/`
- `upstream/kolab/calendar/`
- `upstream/kolab/libcalendaring/`
- `upstream/kolab/libkolab/`
- `installer/`
- `docs/`
- `patches/`
- `smoke-tests/`

## Política de patch

O objetivo aqui não é reescrever os plugins, e sim manter um conjunto mínimo de ajustes para:

- `PHP 8.3+`
- `Roundcube 1.6+`
- instalação manual segura em `Plesk`

## Atualizando o upstream no futuro

1. clone a nova ref upstream em uma área temporária
2. substitua o conteúdo em `upstream/`
3. reaplique os patches necessários do monorepo
4. rode os smoke tests
5. valide o instalador em um `Plesk` de teste

## Smoke tests

```bash
./smoke-tests/php-lint.sh
./smoke-tests/verify-layout.sh
./smoke-tests/verify-elastic-assets.sh
```

## Build de assets

Para gerar os fallbacks no target instalado:

```bash
./installer/build-elastic-assets.sh /usr/share/psa-roundcube
```

Se `lessc` estiver disponível, o script recompila `libkolab.less` em `libkolab.css`. Se não estiver, ele mantém o fallback CSS já versionado no monorepo.

## Observações importantes

- não editar o `composer.json` raiz do `Roundcube` do `Plesk`
- não reintroduzir instruções baseadas em `main.inc.php`
- não depender de `Node 10` ou `PHP 7.0`
- preservar instalação idempotente e rollback por manifesto
