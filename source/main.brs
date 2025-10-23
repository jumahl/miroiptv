sub Main()
    reg = CreateObject("roRegistrySection", "profile")
    if reg.Exists("primaryfeed") then
        url = reg.Read("primaryfeed")
    else
        url = "https://www.m3u.cl/lista/CO.m3u"
    end if

    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)
    m.global = screen.getGlobalNode()
    m.global.addFields({feedurl: url})
    scene = screen.CreateScene("MainScene")
    screen.show()

    ' Fire AppLaunchComplete beacon
    scene.signalBeacon("AppLaunchComplete")

    while(true) 
        msg = wait(0, m.port)
        msgType = type(msg)
        print "msgTYPE >>>>>>>>"; type(msg)
        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed() then return
        else if msgType = "roInputEvent"
            ' Handle deep linking input events
            info = msg.GetInfo()
            if info <> invalid
                print "roInputEvent received: "; FormatJson(info)
                ' Process deep linking parameters if available
                if info.DoesExist("contentId") or info.DoesExist("mediaType")
                    HandleDeepLink(info, scene)
                end if
            end if
        end if
    end while
end sub

' Function to handle deep linking
sub HandleDeepLink(info as Object, scene as Object)
    print "Handling deep link with info: "; FormatJson(info)
    ' You can extend this to handle specific deep linking scenarios
    ' For now, it just logs the info
end sub
