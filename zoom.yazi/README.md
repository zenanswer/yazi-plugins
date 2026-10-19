# zoom.yazi

A fork of [`yazi-rs/plugins:zoom`](https://github.com/yazi-rs/plugins/tree/main/zoom.yazi) for stable image previewing.

The upstream plugin is designed around zoom levels. This fork keeps the same plugin entry point (`zoom`) but focuses on safe, concurrent preview rendering:

- preview images are fitted to the pane while preserving aspect ratio
- a `Loading image WIDTHxHEIGHT…` placeholder is shown while converting
- temporary files live outside the browsed directory, so previewing files in `/tmp` does not trigger Yazi's directory watcher
- temporary files are PID-isolated, so multiple Yazi/SSH sessions do not overwrite each other
- conversions use a fixed scratch file per process and an atomic rename, avoiding partially written PNGs
- stale previews in the persistent cache fallback are cleaned after 180 minutes

## Requirements

- Yazi `26.1.22` or newer
- ImageMagick 7 (`convert`) with PNG support
- a POSIX `sh` and `find` (used for temp-file setup/cleanup)

## Install

```sh
ya pkg add zenanswer/yazi-plugins:zoom
```

Or clone and link for development:

```sh
git clone https://github.com/zenanswer/yazi-plugins.git ~/dev/yazi-plugins
ln -sfn ~/dev/yazi-plugins/zoom.yazi ~/.config/yazi/plugins/zoom.yazi
```

## Configuration

Register it as an image previewer in `~/.config/yazi/yazi.toml`:

```toml
[preview]
max_width = 3840
max_height = 2160
image_quality = 90

[[plugin.prepend_previewers]]
mime = "image/{jpeg,png,gif,webp,bmp}"
run = "zoom"
```

The plugin keeps the `entry` function so existing `plugin zoom <n>` keybindings still resolve, but the current preview path always renders at fit-to-pane size.

## License

MIT. Original work Copyright (c) 2023 yazi-rs; see [LICENSE](LICENSE).
