-- local setmetatable = setmetatable

local policy = require('apicast.policy')
local _M = policy.new('httpbasicauth', '0.1')
-- local mt = { __index = _M }

local new = _M.new

function _M.new(config)
        -- ngx.ctx.auths_configured = config.http_basic_users
        -- ngx.log(ngx.INFO, '_M.new(config) : auths_configured : ', config.http_basic_users)
        -- ngx.ctx.user_authenticated = false
--return setmetatable({}, mt)

-- Patch 25/07/2024 for case 03879019
        local self = new(config)

        if config then
                self.httpbasicauth = config.http_basic_users
                ngx.log(ngx.INFO, '_M.new(config) : self.httpbasicauth = ', config.http_basic_users)
        else
                self.httpbasicauth = nil
                ngx.log(ngx.WARN, '_M.new(config) : config ~FALSE')
        end

        return self
end

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

function _M:rewrite()
        local auth_header = ngx.var.http_authorization

        -- ngx.log output is managed using APICAST_LOG_FILE and APICAST_LOG_LEVEL environment varaibles at APICAST deployment level
        -- oc rsh apicast-xxxx
        -- tail -f /tmp/apicast_log_file.muis | grep -i httpbasicauth.lua
        ngx.log(ngx.INFO, 'auth_header: ', auth_header)


        if auth_header ~= nil and auth_header:find(" ") ~= nil then

                auth_provided = ngx.decode_base64(string.sub(auth_header, 7))

                ngx.log(ngx.INFO, 'auth_provided: ', auth_provided)
                ngx.log(ngx.INFO, 'auths_configured: ', self.httpbasicauth)
                -- ngx.log(ngx.INFO, 'type of auth_provided is', type(auth_provided), ' and type of auths_configured is ', type(self.httpbasicauth))

                auths_configured_split = mysplit(self.httpbasicauth,"|")
                for _, auth_configured in ipairs(auths_configured_split) do
                        auth_provided_split = mysplit(auth_provided,":")
                        auth_configured_split = mysplit(auth_configured,":")
                        -- check if user and pass provided in the http basic auth match (one) current  auth_configured in this for loop
                        ngx.log(ngx.INFO,'auth_provided_split[1]: ', auth_provided_split[1])
                                ngx.log(ngx.INFO,'auth_configured_split[1]: ', auth_configured_split[1])
                                ngx.log(ngx.INFO,'auth_provided_split[2]: ', auth_provided_split[2])
                                ngx.log(ngx.INFO,'auth_configured_split[2]: ',auth_configured_split[2])
                                ngx.log(ngx.INFO, 'type of auth_provided_split[1], auth_configured_split[1], auth_provided_split[2], auth_configured_split[2] are ', type(auth_provided_split[1]), ', ', type(auth_configured_split[1]), ', ', type(auth_provided_split[2]), ', ', type(auth_configured_split[2]))
                        if auth_provided_split[1] == auth_configured_split[1] and auth_provided_split[2] == auth_configured_split[2] then
                                --ngx.ctx.user_authenticated = true
                                ngx.log(ngx.INFO, 'FOUND A MATCH for auth_configured: ', auth_configured)
                                break
                        else
                                ngx.log(ngx.NOTICE, 'NO MATCH for auth_configured: ', auth_configured)
								ngx.status = 403
								ngx.log(ngx.ERR, "Sending back HTTP 403 : HTTP Basic auth credentials does NOT match")
								ngx.say("HTTP Basic auth credentials does NOT match")
                        end
                end
        else
                ngx.log(ngx.ERR, "Informations d'identification manquantes ! Sending back 401")
                ngx.status = 401
                -- ngx.req.set_header('WWW-Authenticate', '123456')
                ngx.header['WWW-Authenticate'] = 'Basic realm="3scale"'
                ngx.say("Informations d'identification manquantes !")
        end

end


--function _M:access()
  -- ability to deny the request before it is sent upstream
  -- ngx.say('HTTP Basic auth credentilas does NOT match')

        --if not ngx.ctx.user_authenticated then
        --        ngx.status = 403
        --        ngx.log(ngx.ERR, "_M:access() : user_authenticated KO. Sending back HTTP 403 : HTTP Basic auth credentials does NOT match")
        --        ngx.say("HTTP Basic auth credentials does NOT match")
        --else
        --        ngx.log(ngx.INFO, "_M:access() : user_authenticated OK")
        --end

  -- ngx.exit(ngx.HTTP_FORBIDDEN)
--end

return _M