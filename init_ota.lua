function LoadX()
    s = {ssid="", pwd="", host="", domain="", path="", err="", boot="", update=0, debug="0"}
    if (file.open("s.txt","r")) then
        local sF = file.read()
        --print("setting: "..sF)
        file.close()
        for k, v in string.gmatch(sF, "([%w.]+)=([%S ]+)") do    
            s[k] = v
            print(k .. ": " .. v)
        end
        if s.debug == "1" and not file.open("debug") then
            file.open("debug", "w")
            file.close()
        elseif s.debug ~= "1" then
            file.remove("debug")
        end

    end
end

function SaveXY(sErr)
    if (sErr) then
        s.err = sErr
    end
    file.remove("s.txt")
    file.open("s.txt","w+")
    for k, v in pairs(s) do
        file.writeline(k .. "=" .. v)
    end                
    file.close()
    collectgarbage()
end

function update()
    if not wifi.sta.getip() then
        print("WiFi not connected")
        return
    end
    conn=net.createConnection(net.TCP, 0)
    conn:on("connection",function(conn, payload)
    conn:send("GET /"..s.path.."/node.php?id="..id.."&update"..
                " HTTP/1.1\r\n".. 
                "Host: "..s.domain.."\r\n"..
                "Accept: */*\r\n"..
                "User-Agent: Mozilla/4.0 (compatible; esp8266 Lua;)"..
                "\r\n\r\n") 
            end)

    conn:on("receive", function(conn, payload)
        if string.find(payload, "UPDATE")~=nil then 
            s.boot=nil
            SaveXY()
            node.restart()
        end
        
        payload = nil
        conn:close()
        conn = nil

    end)
    conn:connect(80,s.host)
end

id = node.chipid()
print ("nodeID is: "..id)

print(collectgarbage("count").." kB used")
LoadX()

if (s.host~="") then
    if (tonumber(s.update)>0) then
        tmr_update = tmr.create()
        tmr_update:alarm (tonumber(s.update)*60000, tmr.ALARM_SEMI, function()
                print("checking for update")
                update()
                tmr_update:start()
            end)
    end
    if (s.boot~="") then
        dofile(s.boot)
    else    
        dofile("client.lua")   
    end
else
    dofile("server.lua")   
end