# yazi-plugins

Personal [Yazi](https://yazi-rs.github.io/) plugins.

## Plugins

| Plugin | Description |
|---|---|
| [`zoom.yazi`](zoom.yazi/) | Image previewer fork with PID-isolated temp files, loading state, aspect-ratio fitting, and stale-file cleanup |

## Install

```sh
ya pkg add zenanswer/yazi-plugins:zoom
```

Then add the previewer to `~/.config/yazi/yazi.toml`:

```toml
[[plugin.prepend_previewers]]
mime = "image/{jpeg,png,gif,webp,bmp}"
run = "zoom"
```

## Development

```sh
git clone https://github.com/zenanswer/yazi-plugins.git ~/dev/yazi-plugins
ln -sfn ~/dev/yazi-plugins/zoom.yazi ~/.config/yazi/plugins/zoom.yazi
```

## License

MIT. `zoom.yazi` is forked from [yazi-rs/plugins](https://github.com/yazi-rs/plugins); the original copyright notice is preserved in [`zoom.yazi/LICENSE`](zoom.yazi/LICENSE).
