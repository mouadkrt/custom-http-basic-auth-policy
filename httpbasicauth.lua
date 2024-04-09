local setmetatable = setmetatable

local _M = require('apicast.policy').new('httpbasicauth', '0.1')
local mt = { __index = _M }

function mysplit (inputstr, sep)
	if sep == nil then
	   sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do 
	   table.insert(t, str)
	end
	return t
 end

function _M.new(config)
	auths_configured = config.http_basic_users
	user_authenticated = false
    return setmetatable({}, mt)
end

function _M:rewrite()
	local auth_header = ngx.var.http_authorization
	
	-- ngx.log output is managed using APICAST_LOG_FILE and APICAST_LOG_LEVEL environment varaibles at APICAST deployment level
	-- oc rsh apicast-xxxx
	-- tail -f /tmp/apicast_log_file.muis | grep -i httpbasicauth.lua
	ngx.log(ngx.INFO, 'auth_header: ', auth_header)
	

	if auth_header ~= nil and auth_header:find(" ") ~= nil then
	
		auth_provided = ngx.decode_base64(string.sub(auth_header, 7))
		
		ngx.log(ngx.INFO, 'auth_provided: ', auth_provided)
		ngx.log(ngx.INFO, 'auths_configured: ', auths_configured)
		
		auths_configured_split = mysplit(auths_configured,"|")
		for _, auth_configured in ipairs(auths_configured_split) do
			auth_provided_split = mysplit(auth_provided,":")
			auth_configured_split = mysplit(auth_configured,":")
			-- check if user and pass provided in the http basic auth match (one) current  auth_configured in this for loop
		        ngx.log(ngx.INFO,'auth_provided_split[1]: ', auth_provided_split[1])
				ngx.log(ngx.INFO,'auth_configured_split[1]: ', auth_configured_split[1])
				ngx.log(ngx.INFO,'auth_provided_split[2]: ', auth_provided_split[2])
				ngx.log(ngx.INFO,'auth_configured_split[2]: ',auth_configured_split[2])
			if auth_provided_split[1]==auth_configured_split[1] and auth_provided_split[2]==auth_configured_split[2] then
				user_authenticated = true
				ngx.log(ngx.INFO, 'FOUND A MATCH for auth_configured: ', auth_configured)
				break
			else
				ngx.log(ngx.WARN, 'NO MATCH for auth_configured: ', auth_configured)
			end
		end
	else
		ngx.log(ngx.STDERR, "Informations d'identification manquantes ! Sending back 401")
		ngx.status = 401
		-- ngx.req.set_header('WWW-Authenticate', '123456')
		ngx.header['WWW-Authenticate'] = 'Basic realm="3scale"'
		ngx.say("Informations d'identification manquantes !")
	end

end


function _M:access()
  -- ability to deny the request before it is sent upstream
  -- ngx.say('HTTP Basic auth credentilas does NOT match')
  
	if not user_authenticated then 
		ngx.status = 403
		ngx.log(ngx.STDERR, "Sending back HTTP 403 : HTTP Basic auth credentials does NOT match")
		ngx.say("HTTP Basic auth credentials does NOT match")
	end
 
  -- ngx.exit(ngx.HTTP_FORBIDDEN)
end

return _M