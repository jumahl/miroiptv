sub init()
    m.top.backgroundURI = "pkg:/images/background-controls.jpg"

    m.save_feed_url = m.top.FindNode("save_feed_url")
    m.get_channel_list = m.top.FindNode("get_channel_list")
    m.get_channel_list.ObserveField("content", "SetContent")
    
    m.playlistList = m.top.FindNode("playlistList")
    m.playlistList.ObserveField("itemSelected", "onPlaylistSelected")
    
    m.channelList = m.top.FindNode("channelList")
    m.channelList.ObserveField("itemSelected", "onChannelSelected")
    
    m.sidePanel = m.top.FindNode("sidePanel")
    m.loadingSpinner = m.top.FindNode("loadingSpinner")
    
    m.channelOverlay = m.top.FindNode("channelOverlay")
    m.channelOverlayList = m.top.FindNode("channelOverlayList")
    m.channelOverlayList.ObserveField("itemSelected", "onOverlayChannelSelected")
    
    if m.loadingSpinner <> invalid then
        m.loadingSpinner.visible = false
    end if

    m.video = m.top.FindNode("Video")
    m.video.ObserveField("state", "checkState")
    
    m.allChannels = invalid
    m.flatChannelList = []
    m.currentChannelIndex = 0
    m.playlists = []
    m.currentPlaylist = 0
    m.isPlayingVideo = false
    m.overlayVisible = false
    
    loadSavedPlaylists()
    setupPlaylistMenu()
    
    if m.playlists.Count() > 0 then
        loadPlaylist(m.playlists[0].url)
    else
        showPlaylistManager()
    end if
End sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    print ">>> KEYEVENT: key = '"; key; "', press = "; press; ", isPlayingVideo = "; m.isPlayingVideo
    result = false
    
    if(press)
        if m.isPlayingVideo then
            if(key = "back")
                m.video.control = "stop"
                m.video.visible = false
                m.channelOverlay.visible = false
                m.channelList.visible = true
                m.sidePanel.visible = true
                m.isPlayingVideo = false
                m.overlayVisible = false
                m.channelList.SetFocus(true)
                m.top.backgroundURI = "pkg:/images/background-controls.jpg"
                result = true
            else if(key = "left")
                print ">>> OVERLAY: Flecha izquierda presionada"
                print ">>> OVERLAY: overlayVisible = "; m.overlayVisible
                print ">>> OVERLAY: allChannels = "; m.allChannels
                
                if m.overlayVisible then
                    print ">>> OVERLAY: Ocultando overlay"
                    m.channelOverlay.visible = false
                    m.overlayVisible = false
                    m.top.setFocus(true)
                else
                    print ">>> OVERLAY: Mostrando overlay"
                    if m.allChannels <> invalid then
                        m.channelOverlay.visible = true
                        m.overlayVisible = true
                        m.channelOverlayList.content = m.allChannels
                        m.channelOverlayList.jumpToItem = m.currentChannelIndex
                        m.channelOverlayList.SetFocus(true)
                        print ">>> OVERLAY: Overlay visible, canales cargados"
                    else
                        print ">>> OVERLAY ERROR: No hay canales disponibles (m.allChannels es invalid)"
                    end if
                end if
                result = true
            else if(key = "right" and m.overlayVisible)
                m.channelOverlay.visible = false
                m.overlayVisible = false
                m.top.setFocus(true)
                result = true
            else if(key = "up")
                print ">>> KEY UP presionado, overlayVisible = "; m.overlayVisible
                if not m.overlayVisible then
                    print ">>> KEY UP: Llamando changeChannel(-1)"
                    changeChannel(-1)
                    result = true
                else
                    print ">>> KEY UP: Overlay visible, tecla pasará al overlay"
                end if
            else if(key = "down")
                print ">>> KEY DOWN presionado, overlayVisible = "; m.overlayVisible
                if not m.overlayVisible then
                    print ">>> KEY DOWN: Llamando changeChannel(1)"
                    changeChannel(1)
                    result = true
                else
                    print ">>> KEY DOWN: Overlay visible, tecla pasará al overlay"
                end if
            end if
        else
            if(key = "right")
                m.sidePanel.visible = true
                m.channelList.SetFocus(true)
                result = true
            else if(key = "left")
                m.sidePanel.visible = true
                m.playlistList.SetFocus(true)
                result = true
            else if(key = "options")
                if m.playlistList.hasFocus() then
                    showPlaylistOptions()
                else
                    showPlaylistManager()
                end if
                result = true
            else if(key = "replay")
                if m.playlistList.hasFocus() then
                    showPlaylistOptions()
                    result = true
                end if
            end if
        end if
    end if
    
    return result 
end function

sub loadSavedPlaylists()
    reg = CreateObject("roRegistrySection", "playlists")
    m.playlists = []
    
    m.playlists.Push({
        name: "Colombia",
        url: "https://www.m3u.cl/lista/CO.m3u",
        isDefault: true
    })
    
    m.playlists.Push({
        name: "Chile",
        url: "https://www.m3u.cl/lista/CL.m3u",
        isDefault: true
    })
    
    m.playlists.Push({
        name: "Argentina",
        url: "https://www.m3u.cl/lista/AR.m3u",
        isDefault: true
    })
    
    m.playlists.Push({
        name: "México",
        url: "https://www.m3u.cl/lista/MX.m3u",
        isDefault: true
    })
    
    m.playlists.Push({
        name: "Ecuador",
        url: "https://www.m3u.cl/lista/EC.m3u",
        isDefault: true
    })
    
    m.playlists.Push({
        name: "Estados Unidos",
        url: "https://www.m3u.cl/lista/US.m3u",
        isDefault: true
    })
    
    if reg.Exists("count") then
        count = reg.Read("count").ToInt()
        for i = 0 to count - 1
            name = reg.Read("name_" + i.ToStr())
            url = reg.Read("url_" + i.ToStr())
            if name <> invalid and url <> invalid then
                m.playlists.Push({name: name, url: url, isDefault: false})
            end if
        end for
    end if
end sub

sub savePlaylist(name as String, url as String)
    reg = CreateObject("roRegistrySection", "playlists")
    
    count = 0
    if reg.Exists("count") then
        count = reg.Read("count").ToInt()
    end if
    
    reg.Write("name_" + count.ToStr(), name)
    reg.Write("url_" + count.ToStr(), url)
    reg.Write("count", (count + 1).ToStr())
    reg.Flush()
    
    m.playlists.Push({name: name, url: url, isDefault: false})
    setupPlaylistMenu()
end sub

sub loadPlaylist(url as String)
    m.global.feedurl = url
    
    if m.loadingSpinner <> invalid then
        m.loadingSpinner.visible = true
    end if
    
    m.get_channel_list.control = "RUN"
end sub

sub setupPlaylistMenu()
    content = CreateObject("roSGNode", "ContentNode")
    
    countryFlags = {
        "Colombia": "🇨🇴",
        "Chile": "🇨🇱",
        "Argentina": "🇦🇷",
        "México": "🇲🇽",
        "Ecuador": "🇪🇨",
        "Estados Unidos": "🇺🇸"
    }
    
    for each playlist in m.playlists
        item = content.CreateChild("ContentNode")
        if playlist.isDefault = true then
            flag = countryFlags[playlist.name]
            if flag <> invalid then
                item.title = flag + " " + playlist.name
            else
                item.title = "⭐ " + playlist.name
            end if
        else
            item.title = "📺 " + playlist.name
        end if
    end for
    
    item = content.CreateChild("ContentNode")
    item.title = "➕ Agregar Lista"
    
    m.playlistList.content = content
    m.playlistList.SetFocus(true)
end sub

sub onPlaylistSelected()
    selectedIdx = m.playlistList.itemSelected
    
    if selectedIdx = m.playlists.Count() then
        showPlaylistManager()
    else if selectedIdx >= 0 and selectedIdx < m.playlists.Count() then
        loadPlaylist(m.playlists[selectedIdx].url)
        m.currentPlaylist = selectedIdx
    end if
end sub

sub showPlaylistOptions()
    selectedIdx = m.playlistList.itemSelected
    
    if selectedIdx < 0 or selectedIdx >= m.playlists.Count() then
        return
    end if
    
    selectedPlaylist = m.playlists[selectedIdx]
    
    if selectedPlaylist.isDefault = true then
        dialog = CreateObject("roSGNode", "Dialog")
        dialog.title = selectedPlaylist.name
        dialog.message = "Las listas predefinidas no se pueden editar o eliminar."
        dialog.buttons = ["OK"]
        m.top.dialog = dialog
        return
    end if
    
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "Opciones: " + selectedPlaylist.name
    dialog.buttons = ["Editar Nombre", "Editar URL", "Eliminar", "Cancelar"]
    dialog.optionsDialog = true
    m.top.dialog = dialog
    m.selectedPlaylistIndex = selectedIdx
    
    dialog.observeFieldScoped("buttonSelected", "onPlaylistOptionSelected")
end sub

sub onPlaylistOptionSelected()
    buttonIdx = m.top.dialog.buttonSelected
    m.top.dialog.close = true
    
    if buttonIdx = 0 then
        editPlaylistName()
    else if buttonIdx = 1 then
        editPlaylistUrl()
    else if buttonIdx = 2 then
        confirmDeletePlaylist()
    end if
end sub

sub editPlaylistName()
    if m.selectedPlaylistIndex = invalid then return
    
    playlist = m.playlists[m.selectedPlaylistIndex]
    
    keyboard = createObject("roSGNode", "KeyboardDialog")
    keyboard.backgroundUri = "pkg:/images/rsgde_bg_hd.jpg"
    keyboard.title = "EDITAR NOMBRE"
    keyboard.message = "Nuevo nombre para la lista"
    keyboard.text = playlist.name
    keyboard.buttons = ["Guardar", "Cancelar"]
    
    m.top.dialog = keyboard
    keyboard.observeFieldScoped("buttonSelected", "onEditNameComplete")
end sub

sub onEditNameComplete()
    if m.top.dialog.buttonSelected = 0 then
        newName = m.top.dialog.text
        if newName <> "" and newName <> invalid then
            playlist = m.playlists[m.selectedPlaylistIndex]
            playlist.name = newName
            
            reg = CreateObject("roRegistrySection", "playlists")
            regIndex = m.selectedPlaylistIndex - 6
            if regIndex >= 0 then
                reg.Write("name_" + regIndex.ToStr(), newName)
                reg.Flush()
            end if
            
            setupPlaylistMenu()
        end if
    end if
    m.top.dialog.close = true
end sub

sub editPlaylistUrl()
    if m.selectedPlaylistIndex = invalid then return
    
    playlist = m.playlists[m.selectedPlaylistIndex]
    
    keyboard = createObject("roSGNode", "KeyboardDialog")
    keyboard.backgroundUri = "pkg:/images/rsgde_bg_hd.jpg"
    keyboard.title = "EDITAR URL"
    keyboard.message = "Nueva URL de la lista M3U"
    keyboard.text = playlist.url
    keyboard.buttons = ["Guardar", "Cancelar"]
    keyboard.keyboard.textEditBox.maxTextLength = 300
    
    m.top.dialog = keyboard
    keyboard.observeFieldScoped("buttonSelected", "onEditUrlComplete")
end sub

sub onEditUrlComplete()
    if m.top.dialog.buttonSelected = 0 then
        newUrl = m.top.dialog.text
        if isValidUrl(newUrl) then
            playlist = m.playlists[m.selectedPlaylistIndex]
            playlist.url = newUrl
            
            reg = CreateObject("roRegistrySection", "playlists")
            regIndex = m.selectedPlaylistIndex - 6
            if regIndex >= 0 then
                reg.Write("url_" + regIndex.ToStr(), newUrl)
                reg.Flush()
            end if
            
            loadPlaylist(newUrl)
        else
            errorDialog = CreateObject("roSGNode", "Dialog")
            errorDialog.title = "Error"
            errorDialog.message = "URL inválida. Debe empezar con http:// o https://"
            errorDialog.buttons = ["OK"]
            m.top.dialog.close = true
            m.top.dialog = errorDialog
            return
        end if
    end if
    m.top.dialog.close = true
end sub

sub confirmDeletePlaylist()
    if m.selectedPlaylistIndex = invalid then return
    
    playlist = m.playlists[m.selectedPlaylistIndex]
    
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "Confirmar eliminación"
    dialog.message = "¿Eliminar '" + playlist.name + "'?"
    dialog.buttons = ["Eliminar", "Cancelar"]
    dialog.optionsDialog = true
    
    m.top.dialog = dialog
    dialog.observeFieldScoped("buttonSelected", "onDeleteConfirmed")
end sub

sub onDeleteConfirmed()
    if m.top.dialog.buttonSelected = 0 then
        regIndex = m.selectedPlaylistIndex - 6
        
        m.playlists.Delete(m.selectedPlaylistIndex)
        
        reg = CreateObject("roRegistrySection", "playlists")
        
        newIndex = 0
        for i = 6 to m.playlists.Count() - 1
            pl = m.playlists[i]
            if pl.isDefault = false then
                reg.Write("name_" + newIndex.ToStr(), pl.name)
                reg.Write("url_" + newIndex.ToStr(), pl.url)
                newIndex = newIndex + 1
            end if
        end for
        
        reg.Write("count", newIndex.ToStr())
        reg.Flush()
        
        setupPlaylistMenu()
        
        if m.playlists.Count() > 0 then
            loadPlaylist(m.playlists[0].url)
        end if
    end if
    m.top.dialog.close = true
end sub

sub showPlaylistManager()
    PRINT ">>> PLAYLIST MANAGER <<<"

    keyboarddialog = createObject("roSGNode", "KeyboardDialog")
    keyboarddialog.backgroundUri = "pkg:/images/rsgde_bg_hd.jpg"
    keyboarddialog.title = "NUEVA LISTA - PASO 1/2"
    keyboarddialog.message = "Nombre de la lista (ej: Mi Canal)"

    keyboarddialog.buttons=["Siguiente","Cancelar"]
    keyboarddialog.optionsDialog=true

    m.top.dialog = keyboarddialog
    m.top.dialog.text = ""
    m.top.dialog.keyboard.textEditBox.maxTextLength = 50

    keyboarddialog.observeFieldScoped("buttonSelected","onPlaylistNameEntered")
end sub

sub onPlaylistNameEntered()
    if m.top.dialog.buttonSelected = 0 then
        name = m.top.dialog.text
        if name = "" or name = invalid then
            name = "Mi Lista"
        end if
        
        m.tempPlaylistName = name
        m.top.dialog.close = true
        
        urlDialog = createObject("roSGNode", "KeyboardDialog")
        urlDialog.backgroundUri = "pkg:/images/rsgde_bg_hd.jpg"
        urlDialog.title = "NUEVA LISTA - PASO 2/2"
        urlDialog.message = "URL de la lista M3U"
        urlDialog.buttons=["Agregar","Cancelar"]
        urlDialog.keyboard.textEditBox.maxTextLength = 300
        
        m.top.dialog = urlDialog
        urlDialog.observeFieldScoped("buttonSelected","onPlaylistUrlEntered")
    else
        m.top.dialog.close = true
    end if
end sub

sub onPlaylistUrlEntered()
    if m.top.dialog.buttonSelected = 0 then
        url = m.top.dialog.text
        if not isValidUrl(url) then
            errorDialog = CreateObject("roSGNode", "Dialog")
            errorDialog.title = "Error"
            errorDialog.message = "URL inválida. Debe empezar con http:// o https://"
            m.top.dialog.close = true
            m.top.dialog = errorDialog
            return
        end if
        
        if m.tempPlaylistName <> invalid then
            savePlaylist(m.tempPlaylistName, url)
            loadPlaylist(url)
        end if
        
        m.top.dialog.close = true
    else
        m.top.dialog.close = true
    end if
end sub

sub checkState()
    state = m.video.state
    if(state = "error")
        m.top.dialog = CreateObject("roSGNode", "Dialog")
        m.top.dialog.title = "Error: " + str(m.video.errorCode)
        m.top.dialog.message = m.video.errorMsg
    end if
end sub

sub SetContent()
    if m.loadingSpinner <> invalid then
        m.loadingSpinner.visible = false
    end if
    
    if m.get_channel_list.content <> invalid then
        m.allChannels = m.get_channel_list.content
        buildFlatChannelList()
        
        if m.flatChannelList.Count() > 0 and m.currentChannelIndex = 0 then
            m.currentChannelIndex = 0
            print ">>> SETCONTENT: Inicializado currentChannelIndex = 0"
        end if
        
        m.channelList.content = m.allChannels
        m.channelList.SetFocus(true)
    else
        errorDialog = CreateObject("roSGNode", "Dialog")
        errorDialog.title = "Error"
        errorDialog.message = "No se pudo cargar la lista. Verifica la URL."
        m.top.dialog = errorDialog
    end if
end sub

sub buildFlatChannelList()
    m.flatChannelList = []
    
    if m.allChannels = invalid then return
    
    for i = 0 to m.allChannels.getChildCount() - 1
        section = m.allChannels.getChild(i)
        if section = invalid then continue for
        
        if section.getChildCount() = 0 then
            m.flatChannelList.Push(section)
        else
            for j = 0 to section.getChildCount() - 1
                channel = section.getChild(j)
                if channel <> invalid then
                    m.flatChannelList.Push(channel)
                end if
            end for
        end if
    end for
    
    print "Total canales en lista plana: "; m.flatChannelList.Count()
end sub

sub changeChannel(direction as Integer)
    print ">>> CHANGECHANNEL: Llamado con direction = "; direction
    print ">>> CHANGECHANNEL: flatChannelList.Count() = "; m.flatChannelList.Count()
    print ">>> CHANGECHANNEL: currentChannelIndex = "; m.currentChannelIndex
    
    if m.flatChannelList.Count() = 0 then 
        print ">>> CHANGECHANNEL ERROR: flatChannelList está vacío!"
        return
    end if
    
    m.currentChannelIndex = m.currentChannelIndex + direction
    
    if m.currentChannelIndex < 0 then
        m.currentChannelIndex = m.flatChannelList.Count() - 1
    else if m.currentChannelIndex >= m.flatChannelList.Count() then
        m.currentChannelIndex = 0
    end if
    
    print ">>> CHANGECHANNEL: Nuevo índice = "; m.currentChannelIndex
    
    channel = m.flatChannelList[m.currentChannelIndex]
    if channel <> invalid then
        print ">>> CHANGECHANNEL: Reproduciendo canal: "; channel.title
        playChannel(channel)
    else
        print ">>> CHANGECHANNEL ERROR: Canal es invalid en índice "; m.currentChannelIndex
    end if
end sub

sub onChannelSelected()
    selectChannelFromList(m.channelList)
end sub

sub onOverlayChannelSelected()
    selectChannelFromList(m.channelOverlayList)
    m.channelOverlay.visible = false
    m.overlayVisible = false
end sub

sub selectChannelFromList(list as Object)
    print ">>> SELECTCHANNEL: Seleccionando canal de lista"
    
    if list.content = invalid or list.content.getChildCount() = 0 then
        print ">>> SELECTCHANNEL ERROR: Contenido inválido"
        return
    end if
    
    firstChild = list.content.getChild(0)
    if firstChild = invalid then 
        print ">>> SELECTCHANNEL ERROR: firstChild inválido"
        return
    end if
    
    content = invalid
    
    if firstChild.getChildCount() = 0 then
        content = list.content.getChild(list.itemSelected)
        print ">>> SELECTCHANNEL: Sin grupos, itemSelected = "; list.itemSelected
    else
        itemSelected = list.itemSelected
        sectionContent = list.content.getChild(list.currFocusSection)
        if sectionContent = invalid then 
            print ">>> SELECTCHANNEL ERROR: sectionContent inválido"
            return
        end if
        content = sectionContent.getChild(itemSelected)
        print ">>> SELECTCHANNEL: Con grupos, section = "; list.currFocusSection; ", item = "; itemSelected
    end if
    
    if content = invalid then 
        print ">>> SELECTCHANNEL ERROR: content final inválido"
        return
    end if
    
    print ">>> SELECTCHANNEL: Canal seleccionado: "; content.title
    print ">>> SELECTCHANNEL: URL: "; content.url
    
    findChannelIndexByUrl(content.url)
    
    print ">>> SELECTCHANNEL: currentChannelIndex establecido en = "; m.currentChannelIndex
    playChannel(content)
end sub

sub findChannelIndexByUrl(url as String)
    if m.flatChannelList = invalid or m.flatChannelList.Count() = 0 then
        print ">>> FINDINDEX ERROR: flatChannelList está vacío"
        m.currentChannelIndex = 0
        return
    end if
    
    for i = 0 to m.flatChannelList.Count() - 1
        channel = m.flatChannelList[i]
        if channel <> invalid and channel.url = url then
            m.currentChannelIndex = i
            print ">>> FINDINDEX: Canal encontrado en índice "; i
            return
        end if
    end for
    
    print ">>> FINDINDEX: Canal NO encontrado, usando índice 0"
    m.currentChannelIndex = 0
end sub

sub playChannel(content as Object)
	content.streamFormat = "hls, mp4, mkv, mp3, avi, m4v, ts, mpeg-4, flv, vob, ogg, ogv, webm, mov, wmv, asf, amv, mpg, mp2, mpeg, mpe, mpv, mpeg2"

	if m.video.content <> invalid and m.video.content.url = content.url then 
		print ">>> PLAY: Mismo canal, no recargar"
		return
	end if

	print ">>> PLAY: Reproduciendo canal: "; content.title

	content.HttpSendClientCertificates = true
	content.HttpCertificatesFile = "common:/certs/ca-bundle.crt"
	m.video.EnableCookies()
	m.video.SetCertificatesFile("common:/certs/ca-bundle.crt")
	m.video.InitClientCertificates()

	m.video.content = content

	m.top.backgroundURI = "pkg:/images/rsgde_bg_hd.jpg"
	m.video.trickplaybarvisibilityauto = false
	
	m.video.visible = true
	m.video.translation = [0, 0]
	m.video.width = 1920
	m.video.height = 1080
	
	m.channelList.visible = false
	m.sidePanel.visible = false
	
	if not m.overlayVisible then
		m.channelOverlay.visible = false
	end if
	
	m.isPlayingVideo = true
	
	m.video.control = "play"
	m.top.setFocus(true)
	
	print ">>> PLAY: Video iniciado, control = play"
	print ">>> PLAY: Foco establecido en Scene para capturar teclas"
end sub

function isValidUrl(url as String) as Boolean
    if url = "" then return false
    
    httpReg = CreateObject("roRegex", "^https?://", "i")
    if not httpReg.isMatch(url) then return false
    
    urlReg = CreateObject("roRegex", "^https?://[^\s/$.?#].[^\s]*$", "i")
    return urlReg.isMatch(url)
end function
