<?php

if ($argc < 3) {
    fwrite(STDERR, "Usage: php ensure-roundcube-include.php <config.inc.php> <fragment-filename>\n");
    exit(1);
}

$configPath = $argv[1];
$fragmentName = $argv[2];
$includeLine = "@include_once __DIR__ . '/{$fragmentName}';";

if (!is_file($configPath) || !is_readable($configPath)) {
    fwrite(STDERR, "Config file not readable: {$configPath}\n");
    exit(1);
}

$contents = file_get_contents($configPath);

if ($contents === false) {
    fwrite(STDERR, "Failed to read config file: {$configPath}\n");
    exit(1);
}

if (strpos($contents, $includeLine) !== false) {
    fwrite(STDOUT, "unchanged\n");
    exit(0);
}

$insertion = "\n// Managed by callendar installer\n{$includeLine}\n";

if (preg_match('/\?>\s*$/', $contents)) {
    $updated = preg_replace('/\?>\s*$/', rtrim($insertion) . "\n?>\n", $contents, 1);
} else {
    $updated = rtrim($contents) . $insertion;
}

if (file_put_contents($configPath, $updated) === false) {
    fwrite(STDERR, "Failed to write config file: {$configPath}\n");
    exit(1);
}

fwrite(STDOUT, "updated\n");
