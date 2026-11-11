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

function getinfo(cmd, nonwline)
	local tmp = io.popen(cmd)

	local info = tmp:read('*a')
	if nonwline then
		info = string.gsub(info, '[\n+]', '')
	end

	tmp:close()

	return info
end

function getmemory()
	local totalmem = getinfo("awk '/MemTotal/ {print $2}' /proc/meminfo", true)
	if totalmem/1000000 < 0.85 then
		if totalmem/1000 < 0.85 then
			totalmem = string.format('%.2f KB', totalmem/1000)
		else
			totalmem = string.format('%.2f MB', totalmem/1000)
		end
	else
		totalmem = string.format('%.2f GB', totalmem/1000000)
	end
	
	local availmem = getinfo("awk '/MemAvailable/ {print $2}' /proc/meminfo", true)
	if availmem/1000000 < 0.85 then
		if availmem/1000 < 0.85 then
			availmem = string.format('%.2f KB', availmem/1000)
		else
			availmem = string.format('%.2f MB', availmem/1000)
		end
	else
		availmem = string.format('%.2f GB', availmem/1000000)
	end

	local mem = availmem .. ' / ' .. totalmem
	return mem
end

function getuptime()
	local uptimeinfo = io.open('/proc/uptime')
	local uptime = ''

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
		local boot = math.tointeger(getinfo('date -d"$(uptime -s)" +%s', true))
		local time = math.tointeger(getinfo('date +%s', true))

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
	local osName = string.match(OS, '(%S*)%s+')

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
				pkgs = string.gsub(pkgs .. '(' .. p[1] .. ') ' .. num .. ' ', '[\n+]', '')

				tmp:close()
			end
		end
	end

	return pkgs
end

user = os.getenv('USER') or 'UNKOWN'
shell = os.getenv('SHELL') or 'UNKOWN'
term = os.getenv('TERM') or 'UNKOWN'

OS = getinfo('uname -s -m', true) or 'UNKOWN'
hostname = getinfo('hostname', true) or 'UNKOWN'

mem = getmemory() or 'UNKOWN'
uptime = getuptime() or 'UNKOWN'
pkgs = getpackages() or 'UNKOWN'

cpu = getinfo("awk -F':' '/model name/ {print $2; exit}' /proc/cpuinfo | xargs",
				true) or 'UNKOWN'

gpu = getinfo("lspci | grep -iE ' Display | 3D | VGA ' | awk -F'[][]' '{print $(NF-1)}'", 
				true) or 'UNKOWN'

title = user .. '@' .. hostname
sep = string.rep('-', string.len(user)) .. '-' .. string.rep('-', string.len(hostname))

for _, c in pairs(config) do
	if (c ~= 'title') and (c ~= 'sep') then
		print('\x1b[1m' .. string.upper(c) .. ': ' .. '\x1b[0m' .. _G[c])
	else
		print('\x1b[1m' .. _G[c] .. '\x1b[0m')
	end
end