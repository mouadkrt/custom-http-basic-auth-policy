local setmetatable = setmetatable

local _M = require('apicast.policy').new('httpbasicauth', '0.1')
local mt = { __index = _M }


function _M.new(config)
		
	auths_configured = config.http_basic_users
	user_authenticated = false
	
   return setmetatable({}, mt)
end

function _M:init()
  -- do work when nginx master process starts
end

function _M:init_worker()
  -- do work when nginx worker process is forked from master
end

function _M:rewrite()

	-- For debug puprose :
		file = io.open("/tmp/http_basic_auth.lua.out", "a")
		io.output(file)
	
	local auth_header = ngx.var.http_authorization
	
	io.write("\n\nauth_header : " .. tostring(auth_header) .. "\n")
	
	if auth_header ~= nil and auth_header:find(" ") ~= nil then
	
		auth_provided = ngx.decode_base64(string.sub(auth_header, 7))
  
		io.write("auth_provided : |" .. tostring(auth_provided) .. "|\n")
		io.write("auths_configured : |" .. tostring(auths_configured) .. "|\n")
		
		pos = string.find(string.lower(auths_configured),auth_provided,true)
		--io.write("pos : |" .. tostring(pos) .. "|\n")
		
		if pos ~= nil then
			user_authenticated = true
		end
	end
	
	io.close(file)
end


function _M:access()
  -- ability to deny the request before it is sent upstream
  -- ngx.say('HTTP Basic auth credentilas does NOT match')
  
	if not user_authenticated then 
		ngx.status = 403
		ngx.say("HTTP Basic auth credentials does NOT match")
	end
 
  -- ngx.exit(ngx.HTTP_FORBIDDEN)
end

function _M:content()
  -- can create content instead of connecting to upstream
end

function _M:post_action()
  -- do something after the response was sent to the client
end

function _M:header_filter()
  -- can change response headers
end

function _M:body_filter()
  -- can read and change response body
  -- https://github.com/openresty/lua-nginx-module/blob/master/README.markdown#body_filter_by_lua
end

function _M:log()
  -- can do extra logging
end

function _M:balancer()
  -- use for example require('resty.balancer.round_robin').call to do load balancing
end

return _M