<?php

$managed_plugins = json_decode('__PLUGIN_JSON__', true) ?: [];
$config['plugins'] = array_values(array_unique(array_merge((array) ($config['plugins'] ?? []), $managed_plugins)));
