--- @since 26.1.22

local get = ya.sync(function(st, url)
	return st.last == url and st.level
end)

local save = ya.sync(function(st, url, new)
	local h = cx.active.current.hovered
	if h and h.url == url then
		st.last, st.level = url, new
		return true
	end
end)

local lock = ya.sync(function(st, url, old, new)
	if st.last == url and st.level == old then
		st.level = new
		return true
	end
end)

local move = ya.sync(function(st)
	local h = cx.active.current.hovered
	if not h then
		return
	end

	if st.last ~= h.url then
		st.last, st.level = Url(h.url), 0
	end

	return { url = h.url, level = st.level }
end)

local function end_(job, err)
	if not job.old_level then
		ya.preview_widget(job, err and ui.Text(err):area(job.area):wrap(ui.Wrap.YES))
	elseif err then
		ya.notify({ title = "Zoom", content = tostring(err), timeout = 5, level = "error" })
	end
end

local function canvas(area)
	local cw, ch = rt.term.cell_size()
	if not cw then
		return rt.preview.max_width, rt.preview.max_height
	end

	return math.min(rt.preview.max_width, math.floor(area.w * cw)),
		math.min(rt.preview.max_height, math.floor(area.h * ch))
end

-- Temporary files live outside the browsed directory (so previewing inside /tmp
-- cannot trigger yazi's directory watcher). Each yazi process writes to its own
-- PID-named file, so multiple SSH sessions never overwrite each other's preview.
local stable, scratch
local function temp_files()
	if stable then
		return stable, scratch
	end

	local dir = os.getenv("XDG_RUNTIME_DIR")
	local cache = false
	if not dir or dir == "" then
		dir = os.getenv("XDG_CACHE_HOME") or ((os.getenv("HOME") or "/tmp") .. "/.cache")
		dir = dir .. "/yazi"
		cache = true
	end
	dir = dir .. "/yazi-zoom"

	Command("mkdir"):arg({ "-p", dir }):output()
	if cache then
		-- In the persistent cache fallback, drop leftovers from dead processes.
		Command("find"):arg({
			dir,
			"-maxdepth",
			"1",
			"-type",
			"f",
			"-name",
			"preview-*",
			"-mmin",
			"+180",
			"-delete",
		}):output()
	end

	local pid = "0"
	local out = Command("sh"):arg({ "-c", "echo $PPID" }):output()
	if out and out.status.success then
		pid = (out.stdout:gsub("%s+$", ""))
	end

	stable = string.format("%s/preview-%s.png", dir, pid)
	-- A fixed scratch name per process: a cancelled/aborted conversion (hover
	-- moved away, pane resized) is overwritten by the next one instead of
	-- leaving a new partial file behind every time.
	scratch = string.format("%s/preview-%s.tmp", dir, pid)

	return stable, scratch
end

function peek(self, job)
	local info, err = ya.image_info(job.file.url)
	if not info then
		ya.preview_widget(job, ui.Text(err or "Failed to get image info"):area(job.area):wrap(ui.Wrap.YES))
		return
	end

	-- Fit the image to the preview area in pixels, preserving aspect ratio.
	-- Recalculated on every redraw, so resizing the pane rescales the image.
	local new_w, new_h = canvas(job.area)
	if not new_w or not new_h or new_w < 1 or new_h < 1 then
		return
	end

	-- Converting and transmitting a large image takes a beat; show what's
	-- happening instead of leaving the preview area blank.
	local msg = string.format("Loading image %d×%d…", info.w or 0, info.h or 0)
	local pad = string.rep("\n", math.max(0, math.floor(job.area.h / 2) - 1))
	ya.preview_widget(
		job,
		ui.Text(pad .. msg):area(job.area):wrap(ui.Wrap.YES)
	)

	local stable, scratch = temp_files()
	if not stable then
		ya.preview_widget(job, ui.Text("Failed to create a temporary file"):area(job.area))
		return
	end

	local output, err = Command("convert"):arg({
		tostring(job.file.path),
		"-auto-orient",
		"-strip",
		"-filter",
		"Lanczos",
		"-resize",
		string.format("%dx%d", new_w, new_h),
		"-quality",
		rt.preview.image_quality,
		"PNG:" .. scratch,
	}):output()

	if not output then
		ya.preview_widget(job, ui.Text("convert error: " .. tostring(err)):area(job.area))
	elseif not output.status.success then
		os.remove(scratch)
		ya.preview_widget(job, ui.Text("convert failed: " .. tostring(output.stderr)):area(job.area):wrap(ui.Wrap.YES))
	elseif not os.rename(scratch, stable) then
		os.remove(scratch)
		ya.preview_widget(job, ui.Text("Failed to rename the temporary file"):area(job.area))
	else
		-- Atomic rename keeps readers from ever seeing a half-written PNG when a
		-- resize cancels the previous preview mid-conversion.
		ya.preview_widget(job, nil)
		ya.image_show(Url(stable), job.area)
	end
end

local function entry(self, job)
	local st = move()
	if not st then
		return
	end

	local motion = tonumber(job.args[1]) or 0
	local new = ya.clamp(-10, st.level + motion, 10)
	if new ~= st.level then
		peek(self, {
			area = ui.area("preview"),
			args = {},
			file = File({ url = st.url, cha = Cha({ mode = tonumber("100644", 8) }) }),
			skip = 0,
			new_level = new,
			old_level = st.level,
		})
	end
end

return { peek = peek, entry = entry }
