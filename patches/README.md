# Inventário de patches

## automatic_addressbook

- guards para `Undefined array key` e variáveis indefinidas em `PHP 8.x`
- remoção de compatibilidade herdada de `Roundcube 0.x` no fluxo principal
- backend respeitando `db_table_collected_contacts`
- `composer.json` atualizado para `PHP 8.1+` e `Roundcube 1.6+`
- `INSTALL` reescrito para instalação moderna
- `package.xml` ajustado para refletir os arquivos reais

## stack Kolab

- `composer.json` atualizados para `roundcube/plugin-installer >= 0.3.0`
- fallbacks de CSS para a skin `Elastic`
- assets `Elastic` materializados no monorepo
- `README` do `calendar` atualizado com SQL por backend

## Observação

Os patches são mantidos diretamente sobre os arquivos importados em `upstream/`, enquanto este diretório documenta o escopo das mudanças aplicadas.
