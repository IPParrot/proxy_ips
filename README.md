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
- Minimal dependencies (Req for HTTP, Flow for concurrency)

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

### Testing Implementation
All proxy testing (HTTP/HTTPS/SOCKS4/SOCKS5) uses **Katipo** (Erlang NIF wrapping libcurl):

Katipo provides:
- Native performance (no process spawning overhead)
- Connection pooling (100 concurrent workers)
- Native BEAM integration
- Unified API for all protocols

These settings match the reference implementation from [free-proxy-list](https://github.com/NikolaiT/free-proxy-list) for consistent results.

## Performance & Timing Estimates

### Configuration
- **Concurrent tests**: 80 (8 Flow stages × 10 max demand)
- **Katipo pool**: 100 workers
- **Timeouts**: 5s connect, 15s total

### Expected Processing Times

For ~400,000 total proxies (HTTP/HTTPS/SOCKS4/SOCKS5):

| Scenario | Proxies Tested | Time |
|----------|---------------|------|
| **First Run** (no cache) | 406,802 | 7-21 hours |
| **Average** (mixed) | 406,802 | ~11 hours |
| **Best Case** (fast failures) | 406,802 | ~7 hours |
| **Subsequent Runs** (90% cached) | ~40,680 | ~1 hour |

**Key Optimizations:**
- ✅ Katipo NIF: No process spawn overhead (~10 min saved vs curl)
- ✅ Connection pooling: Reused connections across requests
- ✅ Result caching: 18-hour cache skips retesting
- ✅ Parallel testing: 80 concurrent tests

**Note**: Actual time varies based on network conditions and proxy response rates. The 18-hour result cache dramatically speeds up subsequent runs.

### Progress Tracking

The scraper reports real-time progress during testing:

```
Progress: 4068/40680 (10.0%) | Rate: 12.45/sec | ETA: 48m 32s
Progress: 8136/40680 (20.0%) | Rate: 13.12/sec | ETA: 41m 18s
Progress: 12204/40680 (30.0%) | Rate: 13.67/sec | ETA: 34m 42s
```

Progress updates show:
- **Completed/Total**: Number of proxies tested
- **Percentage**: Progress percentage
- **Rate**: Proxies tested per second
- **ETA**: Estimated time remaining

Progress is reported every 5% completion.

## Local Usage

### Install dependencies

```bash
mix deps.get
```

### Compile dependencies (includes Katipo NIF)

```bash
mix compile
```

### Run the proxy collector

```bash
mix proxy_ips
```

This will:
1. Fetch proxy lists from multiple sources
2. Test each proxy for connectivity (using Katipo for SOCKS, Req for HTTP/HTTPS)
3. Save working proxies to text files in `proxies/`

**Note**: Run via Mix task (not escript) to support Katipo's NIF dependencies.

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

## Testing Proxies

### HTTP Proxy
```bash
curl -x http://PROXY_IP:PORT https://httpbin.org/ip -k
```

### HTTPS Proxy
```bash
curl -x https://PROXY_IP:PORT https://httpbin.org/ip -k
```

### SOCKS4 Proxy
```bash
curl --socks4 PROXY_IP:PORT https://httpbin.org/ip
```

### SOCKS5 Proxy
```bash
curl --socks5 PROXY_IP:PORT https://httpbin.org/ip
```

## Project Structure

```
proxy_ips/
├── lib/
│   └── proxy_ips/
│       ├── cli.ex          # Main escript entry point
│       ├── sources.ex      # Proxy source URLs
│       ├── scraper.ex      # Fetches proxies from sources
│       ├── tester.ex       # Tests proxy connectivity
│       ├── cache.ex        # Caching system
│       └── csv_writer.ex   # CSV generation
├── proxies/                # Output directory
├── .cache/                 # Cache directory (gitignored)
│   ├── sources/            # Cached proxy list downloads
│   └── results/            # Cached test results
├── .github/
│   └── workflows/
│       └── update_proxies.yml
├── mix.exs
└── README.md
```

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
