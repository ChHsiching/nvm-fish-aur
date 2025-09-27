# nvm-fish Configuration Guide

## Overview

nvm-fish now includes a powerful configuration system that allows you to customize behavior, enable performance optimizations, and debug issues. Configuration is stored in a JSON file in your home directory.

## Configuration File

The configuration file is located at:
```
~/.config/nvm_fish/config.json
```

This file is automatically created with default values the first time nvm-fish runs.

## Configuration Options

### auto_switch
- **Type**: boolean
- **Default**: `true`
- **Description**: Controls automatic Node.js version switching when changing directories

When `true`, nvm-fish will automatically switch Node.js versions when you enter a directory containing a `.nvmrc` file. When `false`, you must manually switch versions using `nvm use`.

Example:
```json
{
  "auto_switch": false
}
```

### cache_enabled
- **Type**: boolean
- **Default**: `true`
- **Description**: Enables directory caching for performance optimization

When enabled, nvm-fish caches the locations of `.nvmrc` files to speed up directory switching. This significantly improves performance in deep directory structures.

### cache_ttl
- **Type**: integer
- **Default**: `300` (5 minutes)
- **Description**: Cache time-to-live in seconds

Determines how long cache entries remain valid. After this period, nvm-fish will re-scan directories for `.nvmrc` files.

### debug_mode
- **Type**: boolean
- **Default**: `false`
- **Description**: Enables debug output for troubleshooting

When enabled, nvm-fish will output debug information including:
- Cache hit/miss statistics
- Performance timing data
- Detailed operation logs

## Default Configuration

```json
{
  "auto_switch": true,
  "cache_enabled": true,
  "cache_ttl": 300,
  "debug_mode": false
}
```

## Performance Optimization

### How Caching Works

nvm-fish uses an intelligent caching system to improve performance:

1. **Directory Scanning**: When you first enter a directory, nvm-fish scans for `.nvmrc` files
2. **Cache Storage**: Results are cached in `~/.config/nvm_fish/directory_cache.fish`
3. **Fast Lookup**: Subsequent visits use cached data instead of re-scanning
4. **Automatic Expiration**: Cache entries expire after `cache_ttl` seconds

### Performance Tips

1. **Enable Caching**: Keep `cache_enabled` set to `true` for best performance
2. **Adjust TTL**: Increase `cache_ttl` if you frequently switch between the same directories
3. **Monitor Performance**: Use debug mode to see cache hit rates and timing

### Cache Management

nvm-fish includes cache management functions:

```fish
# Show cache statistics
__nvm_show_cache_stats

# Clear all cache
__nvm_clear_cache

# Remove entries for non-existent directories
__nvm_purge_invalid_cache
```

## Debug Mode

Debug mode provides detailed information about nvm-fish operations:

```fish
# Enable debug mode in config.json
{
  "debug_mode": true
}

# Or use the debug shell for interactive debugging
__nvm_debug_shell

# Run system diagnostics
__nvm_system_diagnostics

# View performance report
__nvm_show_performance_report
```

## Common Configuration Scenarios

### Disable Automatic Switching

If you prefer to manually control Node.js versions:

```json
{
  "auto_switch": false,
  "cache_enabled": true,
  "cache_ttl": 300,
  "debug_mode": false
}
```

### Maximum Performance

For the best performance in large projects:

```json
{
  "auto_switch": true,
  "cache_enabled": true,
  "cache_ttl": 3600,
  "debug_mode": false
}
```

### Troubleshooting

When experiencing issues:

```json
{
  "auto_switch": true,
  "cache_enabled": true,
  "cache_ttl": 60,
  "debug_mode": true
}
```

## Configuration Management Functions

nvm-fish provides functions for managing configuration:

```fish
# Show current configuration
__nvm_show_config

# Reload configuration from file
__nvm_reload_config

# Reset to defaults
__nvm_reset_config
```

## File Structure

The nvm-fish configuration directory contains:

```
~/.config/nvm_fish/
├── config.json           # Main configuration file
├── directory_cache.fish  # Directory lookup cache
└── performance.log       # Performance log (when debug enabled)
```

## Backward Compatibility

This configuration system is fully backward compatible. Existing installations will continue to work with default settings, and all existing nvm commands function as before.

## Troubleshooting Configuration Issues

### Configuration Not Loading

If your configuration doesn't seem to be applied:

1. Check file permissions on `~/.config/nvm_fish/config.json`
2. Validate JSON syntax
3. Use `__nvm_show_config` to verify loaded values
4. Check for syntax errors in the configuration file

### Cache Issues

If you're experiencing problems with caching:

1. Clear the cache: `__nvm_clear_cache`
2. Verify directory permissions
3. Check available disk space
4. Try reducing `cache_ttl`

### Debug Mode Issues

If debug mode isn't working:

1. Verify `debug_mode` is set to `true` in the configuration
2. Check file permissions on the configuration directory
3. Ensure nvm-fish functions are properly loaded
4. Restart your fish shell after making changes