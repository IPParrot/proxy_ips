# Proxy IPs

An Elixir-based proxy scraper and tester that collects and verifies free proxy servers from multiple sources.

## Features

- Scrapes proxy lists from multiple GitHub sources
- Tests each proxy for connectivity
- Supports multiple protocols: HTTP, HTTPS, SOCKS4, SOCKS5
- Parallel processing using Flow for fast execution
- Caching prevents redundant testing and downloads
- Deduplication skips already tested proxies
- Generates daily updated proxy lists via GitHub Actions

## Output Files

The scraper generates the following files in the `proxies/` directory:

- `http.txt` - Working HTTP proxies (one per line)
- `https.txt` - Working HTTPS proxies (one per line)
- `socks4.txt` - Working SOCKS4 proxies (one per line)
- `socks5.txt` - Working SOCKS5 proxies (one per line)
- `ips.txt` - Unique IP addresses from all working proxies
- `updated_at.txt` - Timestamp of last update
- `proxies.csv` - All working proxies in CSV format with columns: `host,port,protocol,source`

## Quick Download

Download the latest proxy lists without running the tool:

**[Download Latest Release](../../releases/latest)** - Get `proxies.tar.gz` containing all proxy files

The archive updates daily and includes all verified proxy lists. Extract with:
```bash
tar -xzf proxies.tar.gz
```

## Requirements

- Elixir 1.18 or later
- Erlang/OTP 25 or later
- **libcurl** with libevent (required for Katipo NIF)
  - SOCKS4/SOCKS5 proxies are tested using Katipo (Erlang NIF wrapping libcurl)
  - HTTP/HTTPS proxies are tested natively via Elixir's Req library
  - Install: `brew install curl libevent` (macOS), `apt install curl libcurl4-openssl-dev libevent-dev` (Ubuntu/Debian)
  - Katipo compiles a NIF that links against libcurl at build time

## Proxy Testing Configuration

All proxy tests use the following settings (matching curl behavior):

- **Connection timeout**: 5 seconds (`connecttimeout_ms: 5000`)
- **Total timeout**: 15 seconds (`timeout_ms: 15000`)
- **IPv4 preference**: Enabled (via connection options)
- **SSL verification**: Disabled (`ssl_verifypeer: false`)

## Local Usage

### Install dependencies

```bash
mix deps.get
```

### Compile dependencies

```bash
mix compile
```

### Run the proxy collector

```bash
mix proxy_ips
```

## Caching System

The scraper caches results to avoid redundant work:

### Proxy Source Caching (6 hours)
- Downloaded proxy lists are cached for 6 hours
- Reduces load on source servers
- Falls back to stale cache if source is unavailable

### Proxy Test Result Caching (18 hours)
- Each proxy test result is cached for 18 hours
- Prevents retesting recently validated proxies
- Speeds up subsequent runs

### Deduplication
- Skips proxies that were tested within the cache period
- Tracks both working and failed proxies
- Only tests new or expired proxy entries

Cache files are stored in `.cache/` directory:
- `.cache/sources/` - Cached proxy list downloads
- `.cache/results/` - Individual proxy test results (JSON)

To clear the cache and force fresh testing:
```bash
rm -rf .cache/
```

## GitHub Actions

The repository includes a GitHub Actions workflow that:
- Runs daily at 00:00 UTC
- Can be manually triggered via workflow_dispatch
- Tests and verifies all proxies
- Creates a GitHub release with `proxies.tar.gz` containing all files
- Commits and pushes updated proxy lists to the repository

Each run creates a new release tagged with the date and time (e.g., `v2025.01.15-0000`).

## Configuration

### Adding New Proxy Sources

Edit `lib/proxy_ips/sources.ex` and add URLs to the appropriate function:
- `http_sources()`
- `https_sources()`
- `socks4_sources()`
- `socks5_sources()`

### Adjusting Concurrency

Modify the Flow configuration in:
- `lib/proxy_ips/scraper.ex` - `Flow.from_enumerable/2` options
- `lib/proxy_ips/tester.ex` - `Flow.from_enumerable/2` options

## License

MIT
