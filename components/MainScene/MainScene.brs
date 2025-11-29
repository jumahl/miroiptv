sub init()
    m.top.backgroundURI = "pkg:/images/background-controls.jpg"

    m.save_feed_url = m.top.FindNode("save_feed_url")
    m.get_channel_list = m.top.FindNode("get_channel_list")
    m.get_channel_list.ObserveField("content", "SetContent")
    
    m.playlistList = m.top.FindNode("playlistList")
    m.playlistList.ObserveField("itemSelected", "onPlaylistSelected")
    
    m.channelList = m.top.FindNode("channelList")
    m.channelList.ObserveField("itemSelected", "onChannelSelected")
    m.channelList.ObserveField("itemFocused", "onChannelFocused")
    
    m.sidePanel = m.top.FindNode("sidePanel")
    m.loadingSpinner = m.top.FindNode("loadingSpinner")
    
    m.channelOverlay = m.top.FindNode("channelOverlay")
    m.channelOverlayList = m.top.FindNode("channelOverlayList")
    m.channelOverlayList.ObserveField("itemSelected", "onOverlayChannelSelected")
    
    m.channelInfoOverlay = m.top.FindNode("channelInfoOverlay")
    m.channelInfoLabel = m.top.FindNode("channelInfoLabel")
    
    ' Vista previa del video
    m.previewContainer = m.top.FindNode("previewContainer")
    m.previewVideo = m.top.FindNode("PreviewVideo")
    m.previewChannelName = m.top.FindNode("previewChannelName")
    
    if m.previewVideo <> invalid then
        m.previewVideo.EnableCookies()
        m.previewVideo.SetCertificatesFile("common:/certs/ca-bundle.crt")
        m.previewVideo.InitClientCertificates()
    end if
    
    if m.loadingSpinner <> invalid then
        m.loadingSpinner.visible = false
    end if

    m.video = m.top.FindNode("Video")
    m.video.ObserveField("state", "checkState")
    
    m.allChannels = invalid
    m.flatChannelList = []
    m.currentChannelIndex = 0
    m.previewChannelIndex = -1
    m.playlists = []
    m.currentPlaylist = 0
    m.isPlayingVideo = false
    m.overlayVisible = false
    m.lastFocusedChannel = -1
    m.pendingChannelUrl = invalid
    
    loadSavedPlaylists()
    setupPlaylistMenu()
    
    ' Cargar el último estado guardado
    lastState = loadLastState()
    
    if m.playlists.Count() > 0 then
        ' Usar la última playlist si existe, sino la primera
        playlistIndex = 0
        if lastState.playlistIndex <> invalid and lastState.playlistIndex >= 0 and lastState.playlistIndex < m.playlists.Count() then
            playlistIndex = lastState.playlistIndex
        end if
        
        m.currentPlaylist = playlistIndex
        m.playlistList.jumpToItem = playlistIndex
        
        ' Guardar la URL del último canal para seleccionarlo después de cargar la lista
        if lastState.channelUrl <> invalid and lastState.channelUrl <> "" then
            m.pendingChannelUrl = lastState.channelUrl
        end if
        
        loadPlaylist(m.playlists[playlistIndex].url)
    else
        showPlaylistManager()
    end if
    
    ' Signal that the app launch is complete and UI is ready
    m.top.signalBeacon("AppLaunchComplete")
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
                m.previewContainer.visible = true
                m.isPlayingVideo = false
                m.overlayVisible = false
                m.channelList.SetFocus(true)
                m.top.backgroundURI = "pkg:/images/background-controls.jpg"
                
                ' Reanudar vista previa si hay canal enfocado
                if m.lastFocusedChannel >= 0 then
                    playPreviewChannel(m.lastFocusedChannel)
                end if
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
            else if(key = "up" or key = "rewind")
                print ">>> KEY UP/RW presionado, overlayVisible = "; m.overlayVisible
                if not m.overlayVisible then
                    print ">>> KEY UP: Llamando changeChannel(-1)"
                    changeChannel(-1)
                    result = true
                else
                    print ">>> KEY UP: Overlay visible, tecla pasará al overlay"
                end if
            else if(key = "down" or key = "fastforward")
                print ">>> KEY DOWN/FF presionado, overlayVisible = "; m.overlayVisible
                if not m.overlayVisible then
                    print ">>> KEY DOWN: Llamando changeChannel(1)"
                    changeChannel(1)
                    result = true
                else
                    print ">>> KEY DOWN: Overlay visible, tecla pasará al overlay"
                end if
            else if(key = "OK")
                ' Mostrar menú de opciones solo si el video ya está reproduciéndose
                if m.video.state = "playing" or m.video.state = "paused" or m.video.state = "buffering" then
                    showVideoOptionsMenu()
                    result = true
                end if
            else if(key = "play")
                ' Play/Pause del video
                if m.video.state = "playing" then
                    m.video.control = "pause"
                else
                    m.video.control = "resume"
                end if
                result = true
            else if(key = "replay")
                ' Recargar el canal actual (Instant Replay)
                reloadCurrentChannel()
                result = true
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
        m.currentPlaylist = selectedIdx
        m.pendingChannelUrl = invalid ' Limpiar canal pendiente al cambiar de playlist
        loadPlaylist(m.playlists[selectedIdx].url)
        
        ' Guardar la playlist seleccionada
        saveLastState()
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
        m.top.dialog.observeField("buttonSelected", "onDefaultPlaylistDialogClosed")
        return
    end if
    
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "Opciones: " + selectedPlaylist.name
    dialog.buttons = ["Editar Nombre", "Editar URL", "Eliminar", "Cancelar"]
    m.top.dialog = dialog
    m.selectedPlaylistIndex = selectedIdx
    
    m.top.dialog.observeField("buttonSelected", "onPlaylistOptionSelected")
end sub

sub onDefaultPlaylistDialogClosed()
    m.top.dialog.unobserveField("buttonSelected")
    m.top.dialog.close = true
    m.playlistList.setFocus(true)
end sub

sub onPlaylistOptionSelected()
    buttonIdx = m.top.dialog.buttonSelected
    
    m.top.dialog.unobserveField("buttonSelected")
    m.top.dialog.close = true
    
    if buttonIdx = 0 then
        ' Usar timer para esperar que el diálogo se cierre
        m.optionTimer = CreateObject("roSGNode", "Timer")
        m.optionTimer.duration = 0.2
        m.optionTimer.repeat = false
        m.optionTimer.observeField("fire", "editPlaylistName")
        m.optionTimer.control = "start"
    else if buttonIdx = 1 then
        m.optionTimer = CreateObject("roSGNode", "Timer")
        m.optionTimer.duration = 0.2
        m.optionTimer.repeat = false
        m.optionTimer.observeField("fire", "editPlaylistUrl")
        m.optionTimer.control = "start"
    else if buttonIdx = 2 then
        m.optionTimer = CreateObject("roSGNode", "Timer")
        m.optionTimer.duration = 0.2
        m.optionTimer.repeat = false
        m.optionTimer.observeField("fire", "confirmDeletePlaylist")
        m.optionTimer.control = "start"
    else
        m.playlistList.setFocus(true)
    end if
end sub

sub editPlaylistName()
    print ">>> EDIT NAME: Iniciando"
    
    ' Limpiar timer si existe
    if m.optionTimer <> invalid then
        m.optionTimer.unobserveField("fire")
        m.optionTimer = invalid
    end if
    
    if m.selectedPlaylistIndex = invalid then return
    
    playlist = m.playlists[m.selectedPlaylistIndex]
    
    keyboard = createObject("roSGNode", "StandardKeyboardDialog")
    keyboard.backgroundUri = "pkg:/images/rsgde_bg_hd.jpg"
    keyboard.title = "EDITAR NOMBRE"
    keyboard.message = "Nuevo nombre para la lista"
    keyboard.text = playlist.name
    keyboard.buttons = ["Guardar", "Cancelar"]
    
    m.top.dialog = keyboard
    m.top.dialog.observeField("buttonSelected", "onEditNameComplete")
end sub

sub onEditNameComplete()
    print ">>> EDIT NAME: buttonSelected = "; m.top.dialog.buttonSelected
    
    buttonSelected = m.top.dialog.buttonSelected
    
    if buttonSelected = 0 then
        newName = m.top.dialog.text
        
        ' Desregistrar y cerrar el diálogo
        m.top.dialog.unobserveField("buttonSelected")
        m.top.dialog.close = true
        
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
    else
        m.top.dialog.unobserveField("buttonSelected")
        m.top.dialog.close = true
    end if
    
    m.playlistList.setFocus(true)
end sub

sub editPlaylistUrl()
    print ">>> EDIT URL: Iniciando"
    
    ' Limpiar timer si existe
    if m.optionTimer <> invalid then
        m.optionTimer.unobserveField("fire")
        m.optionTimer = invalid
    end if
    
    if m.selectedPlaylistIndex = invalid then return
    
    playlist = m.playlists[m.selectedPlaylistIndex]
    
    keyboard = createObject("roSGNode", "StandardKeyboardDialog")
    keyboard.backgroundUri = "pkg:/images/rsgde_bg_hd.jpg"
    keyboard.title = "EDITAR URL"
    keyboard.message = "Nueva URL de la lista M3U"
    keyboard.text = playlist.url
    keyboard.buttons = ["Guardar", "Cancelar"]
    
    m.top.dialog = keyboard
    m.top.dialog.observeField("buttonSelected", "onEditUrlComplete")
end sub

sub onEditUrlComplete()
    print ">>> EDIT URL: buttonSelected = "; m.top.dialog.buttonSelected
    
    buttonSelected = m.top.dialog.buttonSelected
    
    if buttonSelected = 0 then
        newUrl = m.top.dialog.text
        
        ' Desregistrar y cerrar el diálogo primero
        m.top.dialog.unobserveField("buttonSelected")
        m.top.dialog.close = true
        
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
            ' Mostrar error
            m.pendingErrorMessage = "URL inválida. Debe empezar con http:// o https://"
            m.editUrlErrorTimer = CreateObject("roSGNode", "Timer")
            m.editUrlErrorTimer.duration = 0.3
            m.editUrlErrorTimer.repeat = false
            m.editUrlErrorTimer.observeField("fire", "showEditUrlError")
            m.editUrlErrorTimer.control = "start"
        end if
    else
        m.top.dialog.unobserveField("buttonSelected")
        m.top.dialog.close = true
        m.playlistList.setFocus(true)
    end if
end sub

sub showEditUrlError()
    print ">>> EDIT URL ERROR: Mostrando diálogo de error"
    
    if m.editUrlErrorTimer <> invalid then
        m.editUrlErrorTimer.unobserveField("fire")
        m.editUrlErrorTimer = invalid
    end if
    
    errorDialog = CreateObject("roSGNode", "Dialog")
    errorDialog.title = "Error"
    errorDialog.message = "URL inválida. Debe empezar con http:// o https://"
    errorDialog.buttons = ["OK"]
    
    m.top.dialog = errorDialog
    m.top.dialog.observeField("buttonSelected", "onEditUrlErrorClosed")
end sub

sub onEditUrlErrorClosed()
    m.top.dialog.unobserveField("buttonSelected")
    m.top.dialog.close = true
    m.playlistList.setFocus(true)
end sub

sub confirmDeletePlaylist()
    print ">>> DELETE: Mostrando confirmación"
    
    ' Limpiar timer si existe
    if m.optionTimer <> invalid then
        m.optionTimer.unobserveField("fire")
        m.optionTimer = invalid
    end if
    
    if m.selectedPlaylistIndex = invalid then return
    
    playlist = m.playlists[m.selectedPlaylistIndex]
    
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "Confirmar eliminación"
    dialog.message = "¿Eliminar '" + playlist.name + "'?"
    dialog.buttons = ["Eliminar", "Cancelar"]
    
    m.top.dialog = dialog
    m.top.dialog.observeField("buttonSelected", "onDeleteConfirmed")
end sub

sub onDeleteConfirmed()
    print ">>> DELETE: buttonSelected = "; m.top.dialog.buttonSelected
    
    buttonSelected = m.top.dialog.buttonSelected
    
    m.top.dialog.unobserveField("buttonSelected")
    m.top.dialog.close = true
    
    if buttonSelected = 0 then
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
    
    m.playlistList.setFocus(true)
end sub

sub showPlaylistManager()
    print ">>> PLAYLIST MANAGER: Iniciando paso 1 - Nombre <<<"
    
    ' Limpiar cualquier diálogo anterior
    if m.top.dialog <> invalid then
        m.top.dialog.close = true
        m.top.dialog = invalid
    end if
    
    ' Limpiar timers anteriores
    if m.urlDialogTimer <> invalid then
        m.urlDialogTimer.control = "stop"
        m.urlDialogTimer = invalid
    end if
    
    m.tempPlaylistName = invalid
    
    keyboardDialog = createObject("roSGNode", "StandardKeyboardDialog")
    keyboardDialog.backgroundUri = "pkg:/images/rsgde_bg_hd.jpg"
    keyboardDialog.title = "NUEVA LISTA - PASO 1/2"
    keyboardDialog.message = "Nombre de la lista (ej: Mi Canal)"
    keyboardDialog.buttons = ["Siguiente", "Cancelar"]
    keyboardDialog.text = ""
    
    m.top.dialog = keyboardDialog
    m.top.dialog.observeField("buttonSelected", "onPlaylistNameEntered")
    
    print ">>> PLAYLIST MANAGER: Diálogo de nombre mostrado"
end sub

sub onPlaylistNameEntered()
    print ">>> PLAYLIST NAME: buttonSelected = "; m.top.dialog.buttonSelected
    
    buttonSelected = m.top.dialog.buttonSelected
    
    if buttonSelected = 0 then
        ' Botón "Siguiente" presionado
        name = m.top.dialog.text
        if name = "" or name = invalid then
            name = "Mi Lista"
        end if
        
        m.tempPlaylistName = name
        print ">>> PLAYLIST NAME: Nombre guardado = "; m.tempPlaylistName
        
        ' Cerrar diálogo actual
        m.top.dialog.unobserveField("buttonSelected")
        m.top.dialog.close = true
        
        ' Esperar un momento antes de mostrar el siguiente diálogo
        m.urlDialogTimer = CreateObject("roSGNode", "Timer")
        m.urlDialogTimer.duration = 0.3
        m.urlDialogTimer.repeat = false
        m.urlDialogTimer.observeField("fire", "showUrlDialog")
        m.urlDialogTimer.control = "start"
    else
        ' Botón "Cancelar" presionado
        print ">>> PLAYLIST NAME: Cancelado"
        m.top.dialog.unobserveField("buttonSelected")
        m.top.dialog.close = true
        m.tempPlaylistName = invalid
        
        ' Devolver el foco a la lista
        m.playlistList.setFocus(true)
    end if
end sub

sub showUrlDialog()
    print ">>> URL DIALOG: Iniciando paso 2 - URL <<<"
    
    ' Limpiar timer
    if m.urlDialogTimer <> invalid then
        m.urlDialogTimer.unobserveField("fire")
        m.urlDialogTimer = invalid
    end if
    
    ' Verificar que tenemos el nombre
    if m.tempPlaylistName = invalid then
        print ">>> URL DIALOG ERROR: No hay nombre guardado"
        m.playlistList.setFocus(true)
        return
    end if
    
    urlDialog = createObject("roSGNode", "StandardKeyboardDialog")
    urlDialog.backgroundUri = "pkg:/images/rsgde_bg_hd.jpg"
    urlDialog.title = "NUEVA LISTA - PASO 2/2"
    urlDialog.message = "URL de la lista M3U (ej: https://ejemplo.com/lista.m3u)"
    urlDialog.buttons = ["Agregar", "Cancelar"]
    urlDialog.text = ""
    
    m.top.dialog = urlDialog
    m.top.dialog.observeField("buttonSelected", "onPlaylistUrlEntered")
    
    print ">>> URL DIALOG: Diálogo de URL mostrado"
end sub

sub onPlaylistUrlEntered()
    print ">>> PLAYLIST URL: buttonSelected = "; m.top.dialog.buttonSelected
    
    buttonSelected = m.top.dialog.buttonSelected
    
    if buttonSelected = 0 then
        ' Botón "Agregar" presionado
        url = m.top.dialog.text
        print ">>> PLAYLIST URL: URL ingresada = "; url
        
        ' Desregistrar observer y cerrar diálogo
        m.top.dialog.unobserveField("buttonSelected")
        m.top.dialog.close = true
        
        ' Validar URL
        if url = "" or url = invalid then
            print ">>> PLAYLIST URL ERROR: URL vacía"
            showUrlErrorMessage("La URL no puede estar vacía")
            return
        end if
        
        if not isValidUrl(url) then
            print ">>> PLAYLIST URL ERROR: URL inválida"
            showUrlErrorMessage("URL inválida. Debe empezar con http:// o https://")
            return
        end if
        
        ' Guardar y cargar la playlist
        if m.tempPlaylistName <> invalid then
            print ">>> PLAYLIST URL: Guardando playlist - Nombre: "; m.tempPlaylistName; ", URL: "; url
            savePlaylist(m.tempPlaylistName, url)
            loadPlaylist(url)
        end if
        
        m.tempPlaylistName = invalid
        m.playlistList.setFocus(true)
    else
        ' Botón "Cancelar" presionado
        print ">>> PLAYLIST URL: Cancelado"
        m.top.dialog.unobserveField("buttonSelected")
        m.top.dialog.close = true
        m.tempPlaylistName = invalid
        m.playlistList.setFocus(true)
    end if
end sub

sub showUrlErrorMessage(message as String)
    print ">>> URL ERROR: Mostrando mensaje de error"
    
    ' Usar timer para mostrar el error
    m.pendingErrorMessage = message
    m.errorTimer = CreateObject("roSGNode", "Timer")
    m.errorTimer.duration = 0.3
    m.errorTimer.repeat = false
    m.errorTimer.observeField("fire", "showUrlError")
    m.errorTimer.control = "start"
end sub

sub showUrlError()
    print ">>> URL ERROR: Timer disparado, mostrando diálogo"
    
    if m.errorTimer <> invalid then
        m.errorTimer.unobserveField("fire")
        m.errorTimer = invalid
    end if
    
    message = "URL inválida. Debe empezar con http:// o https://"
    if m.pendingErrorMessage <> invalid then
        message = m.pendingErrorMessage
        m.pendingErrorMessage = invalid
    end if
    
    errorDialog = CreateObject("roSGNode", "Dialog")
    errorDialog.title = "Error"
    errorDialog.message = message
    errorDialog.buttons = ["OK"]
    
    m.top.dialog = errorDialog
    m.top.dialog.observeField("buttonSelected", "onErrorDialogClosed")
end sub

sub onErrorDialogClosed()
    print ">>> ERROR DIALOG: Cerrado"
    m.top.dialog.unobserveField("buttonSelected")
    m.top.dialog.close = true
    m.playlistList.setFocus(true)
end sub

sub checkState()
    state = m.video.state
    if(state = "error")
        ' Mostrar error en el overlay de información en lugar de un diálogo bloqueante
        showChannelError(m.video.errorMsg)
    end if
end sub

sub showChannelError(errorMsg as String)
    if m.channelInfoOverlay = invalid or m.channelInfoLabel = invalid then return
    
    channelNumber = (m.currentChannelIndex + 1).ToStr()
    totalChannels = m.flatChannelList.Count().ToStr()
    
    channel = m.flatChannelList[m.currentChannelIndex]
    channelName = "Canal"
    if channel <> invalid and channel.title <> invalid then
        channelName = channel.title
    end if
    
    m.channelInfoLabel.text = channelNumber + "/" + totalChannels + " - " + channelName + chr(10) + "⚠️ Error: Canal no disponible"
    
    m.channelInfoOverlay.visible = true
    
    ' Crear timer para ocultar el overlay después de 4 segundos
    if m.channelInfoTimer <> invalid then
        m.channelInfoTimer.control = "stop"
    end if
    
    m.channelInfoTimer = CreateObject("roSGNode", "Timer")
    m.channelInfoTimer.duration = 4
    m.channelInfoTimer.repeat = false
    m.channelInfoTimer.ObserveField("fire", "hideChannelInfo")
    m.channelInfoTimer.control = "start"
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
        
        ' Restaurar el último canal si hay uno pendiente
        restorePendingChannel()
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
        showChannelInfo(channel)
        playChannel(channel)
    else
        print ">>> CHANGECHANNEL ERROR: Canal es invalid en índice "; m.currentChannelIndex
    end if
end sub

sub showChannelInfo(channel as Object)
    if m.channelInfoOverlay = invalid or m.channelInfoLabel = invalid then return
    
    channelNumber = (m.currentChannelIndex + 1).ToStr()
    totalChannels = m.flatChannelList.Count().ToStr()
    m.channelInfoLabel.text = channelNumber + "/" + totalChannels + " - " + channel.title
    
    m.channelInfoOverlay.visible = true
    
    ' Crear timer para ocultar el overlay después de 3 segundos
    if m.channelInfoTimer <> invalid then
        m.channelInfoTimer.control = "stop"
    end if
    
    m.channelInfoTimer = CreateObject("roSGNode", "Timer")
    m.channelInfoTimer.duration = 3
    m.channelInfoTimer.repeat = false
    m.channelInfoTimer.ObserveField("fire", "hideChannelInfo")
    m.channelInfoTimer.control = "start"
end sub

sub hideChannelInfo()
    if m.channelInfoOverlay <> invalid then
        m.channelInfoOverlay.visible = false
    end if
end sub

' ==================== MENÚ DE OPCIONES DE VIDEO ====================

sub showVideoOptionsMenu()
    print ">>> VIDEO OPTIONS: Mostrando menú de opciones"
    
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "⚙️ Opciones de Reproducción"
    dialog.buttons = ["🔊 Cambiar Audio", "💬 Subtítulos", "ℹ️ Info del Canal", "❌ Cerrar"]
    
    m.top.dialog = dialog
    m.top.dialog.observeField("buttonSelected", "onVideoOptionSelected")
end sub

sub onVideoOptionSelected()
    buttonIdx = m.top.dialog.buttonSelected
    
    m.top.dialog.unobserveField("buttonSelected")
    m.top.dialog.close = true
    
    if buttonIdx = 0 then
        ' Cambiar pista de audio
        showAudioTracksMenu()
    else if buttonIdx = 1 then
        ' Subtítulos
        showSubtitlesMenu()
    else if buttonIdx = 2 then
        ' Info del canal
        showCurrentChannelInfo()
    end if
    
    m.top.setFocus(true)
end sub

sub showAudioTracksMenu()
    print ">>> AUDIO TRACKS: Obteniendo pistas de audio"
    
    if m.video = invalid then return
    
    ' Obtener información de las pistas de audio disponibles
    ' Intentar múltiples propiedades para compatibilidad
    audioTracks = m.video.audioTracks
    
    print ">>> AUDIO: audioTracks = "; audioTracks
    
    if audioTracks = invalid or audioTracks.Count() = 0 then
        ' Intentar con availableAudioTracks
        audioTracks = m.video.availableAudioTracks
        print ">>> AUDIO: availableAudioTracks = "; audioTracks
    end if
    
    ' Debug: mostrar información del stream
    print ">>> AUDIO: streamInfo = "; m.video.streamInfo
    print ">>> AUDIO: audioFormat = "; m.video.audioFormat
    
    if audioTracks = invalid or audioTracks.Count() = 0 then
        ' Mostrar información de debug
        message = "No se detectaron pistas de audio adicionales." + chr(10) + chr(10)
        message = message + "Formato de audio: " + toStr(m.video.audioFormat) + chr(10)
        message = message + "Estado del video: " + m.video.state
        
        dialog = CreateObject("roSGNode", "Dialog")
        dialog.title = "🔊 Pistas de Audio"
        dialog.message = message
        dialog.buttons = ["OK"]
        m.top.dialog = dialog
        m.top.dialog.observeField("buttonSelected", "onSimpleDialogClosed")
        return
    end if
    
    ' Crear lista de pistas de audio
    m.audioTracksList = []
    buttons = []
    
    ' Obtener pista actual
    currentTrackIndex = -1
    if m.video.currentAudioTrack <> invalid then
        currentTrackIndex = m.video.currentAudioTrack
    end if
    
    for i = 0 to audioTracks.Count() - 1
        track = audioTracks[i]
        trackName = ""
        
        print ">>> AUDIO TRACK "; i; ": "; track
        
        ' Construir nombre de la pista - revisar diferentes propiedades
        language = ""
        if type(track) = "roAssociativeArray" then
            if track.Language <> invalid and track.Language <> "" then
                language = track.Language
            else if track.language <> invalid and track.language <> "" then
                language = track.language
            end if
            
            if language <> "" then
                trackName = getLanguageName(language)
            else
                trackName = "Pista " + (i + 1).ToStr()
            end if
            
            ' Añadir nombre si existe
            if track.Name <> invalid and track.Name <> "" then
                trackName = trackName + " (" + track.Name + ")"
            else if track.name <> invalid and track.name <> "" then
                trackName = trackName + " (" + track.name + ")"
            end if
        else if type(track) = "String" or type(track) = "roString" then
            trackName = getLanguageName(track)
        else
            trackName = "Pista " + (i + 1).ToStr()
        end if
        
        ' Marcar la pista actual
        if i = currentTrackIndex then
            trackName = "✓ " + trackName
        end if
        
        buttons.Push(trackName)
        m.audioTracksList.Push(i)
    end for
    
    buttons.Push("❌ Cancelar")
    
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "🔊 Seleccionar Pista de Audio (" + audioTracks.Count().ToStr() + " disponibles)"
    dialog.buttons = buttons
    
    m.top.dialog = dialog
    m.top.dialog.observeField("buttonSelected", "onAudioTrackSelected")
end sub

function toStr(value as Dynamic) as String
    if value = invalid then return "N/A"
    if type(value) = "String" or type(value) = "roString" then return value
    if type(value) = "Integer" or type(value) = "roInt" then return value.ToStr()
    if type(value) = "Float" or type(value) = "roFloat" then return Str(value)
    return type(value)
end function

sub onAudioTrackSelected()
    buttonIdx = m.top.dialog.buttonSelected
    
    m.top.dialog.unobserveField("buttonSelected")
    m.top.dialog.close = true
    
    if m.audioTracksList <> invalid and buttonIdx < m.audioTracksList.Count() then
        trackIndex = m.audioTracksList[buttonIdx]
        print ">>> AUDIO: Cambiando a pista "; trackIndex
        
        ' Intentar cambiar la pista de audio usando diferentes métodos
        ' Método 1: audioTrack (índice directo)
        m.video.audioTrack = trackIndex
        
        ' Método 2: selectAudioTrack
        m.video.selectAudioTrack = trackIndex
        
        ' Mostrar confirmación
        showChannelInfoMessage("🔊 Audio: Pista " + (trackIndex + 1).ToStr() + " seleccionada")
    end if
    
    m.top.setFocus(true)
end sub

sub showSubtitlesMenu()
    print ">>> SUBTITLES: Obteniendo subtítulos"
    
    if m.video = invalid then return
    
    ' Obtener información de las pistas de subtítulos disponibles
    subtitleTracks = m.video.availableCaptionTracks
    
    buttons = ["❌ Desactivar Subtítulos"]
    m.subtitleTracksList = [-1] ' -1 = desactivar
    
    if subtitleTracks <> invalid and subtitleTracks.Count() > 0 then
        for i = 0 to subtitleTracks.Count() - 1
            track = subtitleTracks[i]
            trackName = ""
            
            if track.Language <> invalid and track.Language <> "" then
                trackName = getLanguageName(track.Language)
            else
                trackName = "Subtítulo " + (i + 1).ToStr()
            end if
            
            if track.Description <> invalid and track.Description <> "" then
                trackName = trackName + " (" + track.Description + ")"
            end if
            
            buttons.Push(trackName)
            m.subtitleTracksList.Push(i)
        end for
    end if
    
    buttons.Push("❌ Cancelar")
    
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "💬 Subtítulos"
    
    if subtitleTracks = invalid or subtitleTracks.Count() = 0 then
        dialog.message = "No hay subtítulos disponibles para este canal."
    end if
    
    dialog.buttons = buttons
    
    m.top.dialog = dialog
    m.top.dialog.observeField("buttonSelected", "onSubtitleTrackSelected")
end sub

sub onSubtitleTrackSelected()
    buttonIdx = m.top.dialog.buttonSelected
    
    m.top.dialog.unobserveField("buttonSelected")
    m.top.dialog.close = true
    
    if m.subtitleTracksList <> invalid and buttonIdx < m.subtitleTracksList.Count() then
        trackIndex = m.subtitleTracksList[buttonIdx]
        
        if trackIndex = -1 then
            print ">>> SUBTITLES: Desactivando subtítulos"
            m.video.suppressCaptions = true
            showChannelInfoMessage("💬 Subtítulos desactivados")
        else
            print ">>> SUBTITLES: Activando subtítulo "; trackIndex
            m.video.suppressCaptions = false
            m.video.selectCaptionTrack = trackIndex
            showChannelInfoMessage("💬 Subtítulos activados")
        end if
    end if
    
    m.top.setFocus(true)
end sub

sub showCurrentChannelInfo()
    if m.flatChannelList = invalid or m.flatChannelList.Count() = 0 then return
    if m.currentChannelIndex < 0 or m.currentChannelIndex >= m.flatChannelList.Count() then return
    
    channel = m.flatChannelList[m.currentChannelIndex]
    if channel = invalid then return
    
    message = "Canal: " + channel.title + chr(10)
    message = message + "Posición: " + (m.currentChannelIndex + 1).ToStr() + " de " + m.flatChannelList.Count().ToStr() + chr(10)
    
    if m.video <> invalid then
        state = m.video.state
        message = message + "Estado: " + state + chr(10)
        
        ' Info de audio
        audioTracks = m.video.availableAudioTracks
        if audioTracks <> invalid then
            message = message + "Pistas de audio: " + audioTracks.Count().ToStr() + chr(10)
        end if
        
        ' Info de subtítulos
        captionTracks = m.video.availableCaptionTracks
        if captionTracks <> invalid then
            message = message + "Subtítulos: " + captionTracks.Count().ToStr()
        end if
    end if
    
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "ℹ️ Información del Canal"
    dialog.message = message
    dialog.buttons = ["OK"]
    
    m.top.dialog = dialog
    m.top.dialog.observeField("buttonSelected", "onSimpleDialogClosed")
end sub

sub onSimpleDialogClosed()
    m.top.dialog.unobserveField("buttonSelected")
    m.top.dialog.close = true
    m.top.setFocus(true)
end sub

sub showChannelInfoMessage(message as String)
    if m.channelInfoOverlay = invalid or m.channelInfoLabel = invalid then return
    
    m.channelInfoLabel.text = message
    m.channelInfoOverlay.visible = true
    
    if m.channelInfoTimer <> invalid then
        m.channelInfoTimer.control = "stop"
    end if
    
    m.channelInfoTimer = CreateObject("roSGNode", "Timer")
    m.channelInfoTimer.duration = 2
    m.channelInfoTimer.repeat = false
    m.channelInfoTimer.ObserveField("fire", "hideChannelInfo")
    m.channelInfoTimer.control = "start"
end sub

function getLanguageName(code as String) as String
    languages = {
        "es": "Español",
        "spa": "Español",
        "spanish": "Español",
        "en": "Inglés",
        "eng": "Inglés",
        "english": "Inglés",
        "pt": "Portugués",
        "por": "Portugués",
        "portuguese": "Portugués",
        "fr": "Francés",
        "fra": "Francés",
        "fre": "Francés",
        "french": "Francés",
        "de": "Alemán",
        "deu": "Alemán",
        "ger": "Alemán",
        "german": "Alemán",
        "it": "Italiano",
        "ita": "Italiano",
        "italian": "Italiano",
        "ja": "Japonés",
        "jpn": "Japonés",
        "japanese": "Japonés",
        "ko": "Coreano",
        "kor": "Coreano",
        "korean": "Coreano",
        "zh": "Chino",
        "chi": "Chino",
        "zho": "Chino",
        "chinese": "Chino",
        "ru": "Ruso",
        "rus": "Ruso",
        "russian": "Ruso",
        "ar": "Árabe",
        "ara": "Árabe",
        "arabic": "Árabe",
        "und": "Desconocido",
        "mul": "Múltiple"
    }
    
    lowerCode = LCase(code)
    if languages.DoesExist(lowerCode) then
        return languages[lowerCode]
    end if
    
    return code
end function

' ==================== VISTA PREVIA DEL CANAL ====================

sub onChannelFocused()
    ' Cuando el usuario navega por la lista de canales, actualizar la vista previa
    if m.isPlayingVideo then return
    if m.channelList = invalid then return
    
    focusedIndex = m.channelList.itemFocused
    print ">>> PREVIEW: Canal enfocado = "; focusedIndex
    
    ' Evitar recargar el mismo canal
    if focusedIndex = m.lastFocusedChannel then return
    m.lastFocusedChannel = focusedIndex
    
    ' Obtener el canal enfocado
    channel = getChannelByFocusIndex(focusedIndex)
    if channel <> invalid then
        playPreviewChannel(focusedIndex)
    end if
end sub

function getChannelByFocusIndex(focusIndex as Integer) as Object
    if m.channelList = invalid or m.channelList.content = invalid then return invalid
    
    content = m.channelList.content
    if content.getChildCount() = 0 then return invalid
    
    firstChild = content.getChild(0)
    if firstChild = invalid then return invalid
    
    ' Si no hay grupos (canales directos)
    if firstChild.getChildCount() = 0 then
        return content.getChild(focusIndex)
    else
        ' Hay grupos, necesitamos calcular el índice correcto
        ' Usar currFocusSection para obtener la sección actual
        if m.channelList.currFocusSection <> invalid then
            section = content.getChild(m.channelList.currFocusSection)
            if section <> invalid then
                ' El itemFocused es relativo a la sección
                return section.getChild(focusIndex)
            end if
        end if
    end if
    
    return invalid
end function

sub playPreviewChannel(channelIndex as Integer)
    if m.previewVideo = invalid then return
    if m.flatChannelList = invalid or m.flatChannelList.Count() = 0 then return
    
    ' Encontrar el canal en la lista plana basándose en el índice de foco
    channel = invalid
    
    ' Intentar obtener el canal directamente de la lista
    if m.channelList <> invalid and m.channelList.content <> invalid then
        content = m.channelList.content
        firstChild = content.getChild(0)
        
        if firstChild <> invalid and firstChild.getChildCount() = 0 then
            ' Sin grupos
            if channelIndex >= 0 and channelIndex < content.getChildCount() then
                channel = content.getChild(channelIndex)
            end if
        else
            ' Con grupos - usar la sección actual
            if m.channelList.currFocusSection <> invalid then
                section = content.getChild(m.channelList.currFocusSection)
                if section <> invalid and channelIndex >= 0 and channelIndex < section.getChildCount() then
                    channel = section.getChild(channelIndex)
                end if
            end if
        end if
    end if
    
    if channel = invalid or channel.url = invalid then 
        print ">>> PREVIEW: No se pudo obtener el canal"
        return
    end if
    
    ' Evitar recargar el mismo canal en preview
    if m.previewVideo.content <> invalid and m.previewVideo.content.url = channel.url then
        return
    end if
    
    print ">>> PREVIEW: Reproduciendo vista previa: "; channel.title
    
    ' Actualizar nombre del canal
    if m.previewChannelName <> invalid then
        m.previewChannelName.text = channel.title
    end if
    
    ' Crear contenido para la vista previa
    previewContent = CreateObject("roSGNode", "ContentNode")
    previewContent.url = channel.url
    previewContent.title = channel.title
    previewContent.streamFormat = "hls"
    previewContent.HttpSendClientCertificates = true
    previewContent.HttpCertificatesFile = "common:/certs/ca-bundle.crt"
    
    m.previewVideo.content = previewContent
    m.previewVideo.control = "play"
    m.previewVideo.mute = true ' Silenciar la vista previa
end sub

sub stopPreviewVideo()
    if m.previewVideo <> invalid then
        m.previewVideo.control = "stop"
        m.previewVideo.visible = false
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

sub reloadCurrentChannel()
    print ">>> RELOAD: Recargando canal actual"
    
    if m.flatChannelList = invalid or m.currentChannelIndex < 0 then
        print ">>> RELOAD ERROR: No hay canal para recargar"
        return
    end if
    
    channel = m.flatChannelList[m.currentChannelIndex]
    if channel = invalid then
        print ">>> RELOAD ERROR: Canal inválido"
        return
    end if
    
    ' Detener el video actual
    m.video.control = "stop"
    
    ' Crear nuevo contenido
    content = CreateObject("roSGNode", "ContentNode")
    content.title = channel.title
    content.url = channel.url
    content.streamFormat = "hls"
    
    print ">>> RELOAD: Recargando: "; channel.title
    
    ' Forzar la recarga saltando la verificación de mismo canal
    m.video.content = invalid
    
    ' Pequeño delay y luego reproducir
    content.HttpSendClientCertificates = true
    content.HttpCertificatesFile = "common:/certs/ca-bundle.crt"
    m.video.EnableCookies()
    m.video.SetCertificatesFile("common:/certs/ca-bundle.crt")
    m.video.InitClientCertificates()
    
    m.video.content = content
    m.video.control = "play"
    m.top.setFocus(true)
    
    print ">>> RELOAD: Canal recargado exitosamente"
end sub

sub playChannel(content as Object)
	content.streamFormat = "hls, mp4, mkv, mp3, avi, m4v, ts, mpeg-4, flv, vob, ogg, ogv, webm, mov, wmv, asf, amv, mpg, mp2, mpeg, mpe, mpv, mpeg2"

	if m.video.content <> invalid and m.video.content.url = content.url then 
		print ">>> PLAY: Mismo canal, no recargar"
		return
	end if

	print ">>> PLAY: Reproduciendo canal: "; content.title

	' Detener la vista previa
	if m.previewVideo <> invalid then
		m.previewVideo.control = "stop"
	end if

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
	m.previewContainer.visible = false
	
	if not m.overlayVisible then
		m.channelOverlay.visible = false
	end if
	
	m.isPlayingVideo = true
	
	m.video.control = "play"
	
	' Asegurar que el Scene tiene el foco para recibir eventos de teclado
	m.video.setFocus(false)
	m.channelList.setFocus(false)
	m.playlistList.setFocus(false)
	m.top.setFocus(true)
	
	' Guardar el estado actual (última playlist y canal)
	saveLastState()
	
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

' ==================== GUARDAR/CARGAR ÚLTIMO ESTADO ====================

sub saveLastState()
    print ">>> SAVE STATE: Guardando último estado"
    
    reg = CreateObject("roRegistrySection", "lastState")
    
    ' Guardar índice de la playlist actual
    reg.Write("playlistIndex", m.currentPlaylist.ToStr())
    
    ' Guardar URL del canal actual
    if m.flatChannelList <> invalid and m.currentChannelIndex >= 0 and m.currentChannelIndex < m.flatChannelList.Count() then
        channel = m.flatChannelList[m.currentChannelIndex]
        if channel <> invalid and channel.url <> invalid then
            reg.Write("channelUrl", channel.url)
            reg.Write("channelTitle", channel.title)
            print ">>> SAVE STATE: Canal guardado = "; channel.title
        end if
    end if
    
    ' Guardar índice del canal (como respaldo)
    reg.Write("channelIndex", m.currentChannelIndex.ToStr())
    
    reg.Flush()
    print ">>> SAVE STATE: Estado guardado exitosamente"
end sub

function loadLastState() as Object
    print ">>> LOAD STATE: Cargando último estado"
    
    state = {
        playlistIndex: 0,
        channelUrl: "",
        channelTitle: "",
        channelIndex: 0
    }
    
    reg = CreateObject("roRegistrySection", "lastState")
    
    if reg.Exists("playlistIndex") then
        state.playlistIndex = reg.Read("playlistIndex").ToInt()
        print ">>> LOAD STATE: playlistIndex = "; state.playlistIndex
    end if
    
    if reg.Exists("channelUrl") then
        state.channelUrl = reg.Read("channelUrl")
        print ">>> LOAD STATE: channelUrl = "; state.channelUrl
    end if
    
    if reg.Exists("channelTitle") then
        state.channelTitle = reg.Read("channelTitle")
        print ">>> LOAD STATE: channelTitle = "; state.channelTitle
    end if
    
    if reg.Exists("channelIndex") then
        state.channelIndex = reg.Read("channelIndex").ToInt()
        print ">>> LOAD STATE: channelIndex = "; state.channelIndex
    end if
    
    return state
end function

sub restorePendingChannel()
    ' Restaurar el canal pendiente después de cargar la lista
    if m.pendingChannelUrl = invalid or m.pendingChannelUrl = "" then return
    
    print ">>> RESTORE: Buscando canal pendiente: "; m.pendingChannelUrl
    
    ' Buscar el canal por URL
    for i = 0 to m.flatChannelList.Count() - 1
        channel = m.flatChannelList[i]
        if channel <> invalid and channel.url = m.pendingChannelUrl then
            m.currentChannelIndex = i
            m.lastFocusedChannel = i
            
            ' Saltar al canal en la lista
            if m.channelList <> invalid then
                m.channelList.jumpToItem = i
            end if
            
            ' Reproducir vista previa del canal
            playPreviewChannel(i)
            
            print ">>> RESTORE: Canal encontrado y seleccionado en índice "; i
            m.pendingChannelUrl = invalid
            return
        end if
    end for
    
    print ">>> RESTORE: Canal no encontrado, usando primer canal"
    m.pendingChannelUrl = invalid
end sub
