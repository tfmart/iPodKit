# Command Line Reference

Reference for the `ipodkit` command line tool.

## Overview

Use `ipodkit --help` or `ipodkit <subcommand> --help` for the reference shipped
with the installed executable.

```bash
ipodkit [--version] [--help]
```

Point any command at a mounted iPod volume, a directory containing database
files, or a database file itself. When no path is given, a mounted iPod is
auto-detected in `/Volumes`.

Pass `--json` for machine-readable output. Standard output carries only the JSON
document and diagnostics go to standard error.

## Global Arguments and Options

- `path`: Path to the iPod volume or database. Omit to auto-detect a mounted
  iPod.

- `--timezone <timezone>`: Device time zone identifier, such as
  `Europe/Lisbon`. Defaults to the current time zone.

- `--json`: Print machine-readable JSON to standard output.

- `--version`: Show the tool version.

- `--help`: Show help information.

## `ipodkit info`

Show summary information about an iPod.

```bash
ipodkit info [<path>] [--timezone <timezone>] [--json]
```

## `ipodkit device`

Show device details, including serial number, settings, sync source, radio
presets, and Bluetooth pairings.

```bash
ipodkit device [<path>] [--timezone <timezone>] [--json]
```

## `ipodkit tracks`

List tracks, optionally filtered.

```bash
ipodkit tracks [<path>] [--timezone <timezone>] [--json]
  [--artist <artist>] [--album <album>] [--genre <genre>]
  [--search <search>] [--playlist <playlist>] [--limit <limit>]
```

- `--artist <artist>`: Filter by artist with a case-insensitive substring match.

- `--album <album>`: Filter by album with a case-insensitive substring match.

- `--genre <genre>`: Filter by genre with a case-insensitive substring match.

- `--search <search>`: Match against title, artist, or album.

- `--playlist <playlist>`: Only list tracks from the playlist with this ID.

- `--limit <limit>`: Maximum number of tracks to print after filtering.

## `ipodkit track`

Show full details for a single track.

```bash
ipodkit track <track-id> [<path>] [--timezone <timezone>] [--json]
```

- `track-id`: Track ID. Use `ipodkit tracks` to list track IDs.

## `ipodkit playlists`

List playlists.

```bash
ipodkit playlists [<path>] [--timezone <timezone>] [--json]
```

## `ipodkit artwork`

Export a track's artwork as a PNG, or list available sizes.

```bash
ipodkit artwork <track-id> [<path>] [--timezone <timezone>]
  [--json] [--output <output>] [--size <size>] [--list]
```

- `track-id`: Track ID. Use `ipodkit tracks` to list track IDs.

- `--output <output>`: Output PNG path. Defaults to
  `artwork-<track-id>.png`.

- `--size <size>`: Thumbnail size to export, such as `140x140`. Defaults to the
  largest available size.

- `--list`: List available artwork sizes without exporting.

## See Also

- <doc:CommandLineTool>
- <doc:GettingStarted>
