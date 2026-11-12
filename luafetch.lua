-- luafetch by rottlog <rottlogg@proton.me>
-- 08.11.2026

local config = {
	'title',
	'sep',
	'OS',
	'uptime',
	'shell',
	'pkgs',
	'term',
	'gpu',
	'cpu',
	'mem'
}

local custom_ascii_path = ''

freebsd_ascii = {
   "           ,        ,         ",
   "          /(        )`        ",
   "          \\ \\___   / |      ",
   "          /- _  `-/  '        ",
   "         (/\\/ \\ \\   /\\    ",
   "         / /   | `    \\      ",
   "         O O   ) /    |       ",
   "         `-^--'`<     '       ",
   "        (_.)  _  )   /        ",
   "         `.___/`    /         ",
   "           `-----' /          ",
   "<----.     __ / __   \\       ",
   "<----|====O)))==) \\) /====",
   "<----'    `--' `.__,' \\   ",
   "             |        |    ",
   "              \\       /   ",
   "         ______( (_  / \\______",
   "      ,'  ,-----'   |        \\",
   "      `--{__________)        \\/"
}
-- by Felix Lee

linux_ascii = {
   "    .--.     ",
   "   |o_o |    ",
   "   |:_/ |    ",
   "  //   \\ \\ ",
   " (|     | )  ",
   "/'\\_   _/`\\",
   "\\___)=(___/ "  
}
-- by Przemek Borys

local longest_line = 0
custom_ascii = {}
if custom_ascii_path ~= '' then
	local custom_ascii_file = io.open(custom_ascii_path)

	if custom_ascii_file then
		for line in custom_ascii_file:lines() do
			if string.len(line) > 0  then
				if string.len(line) > longest_line then
					longest_line = string.len(line)
				end
				table.insert(custom_ascii, line)
			end
		end

		custom_ascii_file:close()
	end
end

function getinfo(cmd)
	local tmp = io.popen(cmd)

	local info = tmp:read('*a')
	info = string.gsub(info, '[\n+]', '')

	if info == '' then info = 'UNKOWN' end

	tmp:close()

	return info
end

function getmemory()
	local mem = 'UNKOWN'

	if (osName == 'FreeBSD') then
		local dmesg = io.open('/var/run/dmesg.boot')

		if dmesg then
			local totalmem = getinfo("awk '/real memory/ {print $4}' /var/run/dmesg.boot")
			if totalmem/1000000000 < 0.85 then
				if totalmem/1000000 < 0.85 then
					totalmem = string.format('%.2f KB', totalmem/1000)
				else
					totalmem = string.format('%.2f MB', totalmem/1000000)
				end
			else
				totalmem = string.format('%.2f GB', totalmem/1000000000)
			end

			local availmem = getinfo("awk '/avail memory/ {print $4}' /var/run/dmesg.boot")
			if availmem/1000000000 < 0.85 then
				if availmem/1000000 < 0.85 then
					availmem = string.format('%.2f KB', availmem/1000)
				else
					availmem = string.format('%.2f MB', availmem/1000000)
				end
			else
				availmem = string.format('%.2f GB', availmem/1000000000)
			end

			mem = availmem .. ' / ' .. totalmem

			dmesg:close()
		end
	end
	if (osName == 'Linux') then
		local meminfo = io.open('/proc/meminfo')

		if meminfo then
			local totalmem = getinfo("awk '/MemTotal/ {print $2}' /proc/meminfo")
			if totalmem/1000000 < 0.85 then
				if totalmem/1000 < 0.85 then
					totalmem = string.format('%.2f KB', totalmem)
				else
					totalmem = string.format('%.2f MB', totalmem/1000)
				end
			else
				totalmem = string.format('%.2f GB', totalmem/1000000)
			end

			local availmem = getinfo("awk '/MemAvailable/ {print $2}' /proc/meminfo")
			if availmem/1000000 < 0.85 then
				if availmem/1000 < 0.85 then
					availmem = string.format('%.2f KB', availmem)
				else
					availmem = string.format('%.2f MB', availmem/1000)
				end
			else
				availmem = string.format('%.2f GB', availmem/1000000)
			end

			mem = availmem .. ' / ' .. totalmem

			meminfo:close()
		end
	end
	return mem
end

function getuptime()
	local uptimeinfo = io.open('/proc/uptime')
	local uptime = 'UNKOWN'

	if uptimeinfo then
		if (getinfo("awk '{printf \"%d\", $1/86400}' /proc/uptime")) ~= '0' then
			uptime = getinfo("awk '{printf \"%d days, %d hours, %d minutes\\n\", $1/86400, $1/3600, ($1%3600)/60}' /proc/uptime",
							true) or 'UNKOWN'
		else
			uptime = getinfo("awk '{printf \"%d hours, %d minutes\\n\", $1/3600, ($1%3600)/60}' /proc/uptime",
							true) or 'UNKOWN' 
		end
		uptimeinfo:close()
	else
		local boot, time
		if (osName == "FreeBSD") then
			boot = math.tointeger(getinfo("sysctl -n kern.boottime | awk -F'[ ,=]+' '{print $3}'"))
			time = math.tointeger(getinfo('date +%s'))
		end
		if (osName == "Linux") then
			boot = math.tointeger(getinfo('date -d"$(uptime -s)" +%s'))
			time = math.tointeger(getinfo('date +%s'))
		end

		local total = (time - boot)
		if (math.floor(total/86400)) ~= 0 then
			uptime = math.floor(total/86400) .. ' days, ' .. math.floor(total/3600) .. ' hours, ' .. math.floor((total%3600)/60) .. ' minutes'
		else
			uptime = math.floor(total/3600) .. ' hours, ' .. math.floor((total%3600)/60) .. ' minutes'
		end
	end

	return uptime
end

function getpackages()
	local pkgs = ''
	local tmpPath = os.tmpname()

	if (osName == 'Linux') or (osName == 'FreeBSD') then
		local pkgMList = {
			{"dpkg", 	"--version", 	"-l | grep -c '^ii'"},
			{"apk", 	"--version", 	"list -i | wc -l"},
			{"pacman", 	"-V", 			"-Q | wc -l"},
			{"pkg", 	"-v", 			"prime-list | wc -l"},
			{"kiss", 	"-v", 			"l | wc -l"},
			{"flatpak", "--version", 	"list | wc -l"}
		} 

		for _, p in pairs(pkgMList) do
			if os.execute(p[1] .. ' ' .. p[2] .. ' > ' .. tmpPath .. ' 2>&1') then
				local tmp = io.popen(p[1] .. ' ' .. p[3])

				local num = tmp:read('*a')
				num = string.match(num, '%s?(%S+)')
				pkgs = pkgs .. '(' .. p[1] .. ') ' .. num .. ' '

				tmp:close()
			end
		end
	end
	if pkgs == '' then pkgs = 'UNKOWN' end
	return pkgs
end

user = getinfo('echo $USER')
shell = getinfo('echo $SHELL')
term = getinfo('echo $TERM')
hostname = getinfo('hostname')

OS = getinfo('uname -s -m')

osName = string.match(OS, '(%S+)%s+')
if (osName == "FreeBSD") then
	cpu = getinfo("sysctl -n hw.model")
	gpu = getinfo("pciconf -lv | grep -B2 display | awk -F\"'\" '/device/ {print $2}'")

	default_ascii = freebsd_ascii
end
if (osName == "Linux") then
	cpu = getinfo("awk -F':' '/model name/ {print $2; exit}' /proc/cpuinfo | xargs")
	gpu = getinfo("lspci | grep -iE ' Display | 3D | VGA ' | awk -F'[][]' '{print $(NF-1)}'")

	default_ascii = linux_ascii
end

mem = getmemory()
uptime = getuptime()
pkgs = getpackages()

title = user .. '@' .. hostname
sep = string.rep('-', string.len(user)) .. '-' .. string.rep('-', string.len(hostname))

local ascii
if custom_ascii_path ~= '' then ascii = custom_ascii
else ascii = default_ascii end

for i, c in pairs(config) do
	space = ''

	if i <= #ascii then
		if custom_ascii_path ~= '' then
			io.write(ascii[i])
		else
			io.write(ascii[i] .. '\t')
		end
		space = string.rep(' ', (longest_line - string.len(ascii[i])) + 1)
	else io.write('\t\t') end

	if (c ~= 'title') and (c ~= 'sep') then
		if _G[c] ~= 'UNKOWN' then			
			output = '\x1b[1m' .. string.upper(c) .. ': ' .. '\x1b[0m' .. _G[c]
		else
			output = '\x1b[1m' .. string.upper(c) .. ': ' .. '\x1b[31m' .. _G[c] .. '\x1b[0m' .. '\x1b[0m'
		end
	else
		output = '\x1b[1m' .. _G[c] .. '\x1b[0m'
	end
	print(space .. output)

	if i == #config and i < #ascii then
		for a=i+1, #ascii do
			print(ascii[a])
		end
	end
end