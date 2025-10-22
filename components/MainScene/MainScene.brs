sub init()
    m.top.backgroundURI = "pkg:/images/background-controls.jpg"

    ' Componentes
    m.save_feed_url = m.top.FindNode("save_feed_url")
    m.get_channel_list = m.top.FindNode("get_channel_list")
    m.get_channel_list.ObserveField("content", "SetContent")
    
    ' UI
    m.playlistList = m.top.FindNode("playlistList")
    m.playlistList.ObserveField("itemSelected", "onPlaylistSelected")
    
    m.channelList = m.top.FindNode("channelList")
    m.channelList.ObserveField("itemSelected", "onChannelSelected")
    
    m.sidePanel = m.top.FindNode("sidePanel")
    m.loadingSpinner = m.top.FindNode("loadingSpinner")
    
    ' Overlay de canales durante reproducción
    m.channelOverlay = m.top.FindNode("channelOverlay")
    m.channelOverlayList = m.top.FindNode("channelOverlayList")
    m.channelOverlayList.ObserveField("itemSelected", "onOverlayChannelSelected")
    
    if m.loadingSpinner <> invalid then
        m.loadingSpinner.visible = false
    end if

    m.video = m.top.FindNode("Video")
    m.video.ObserveField("state", "checkState")
    
    ' Variables de estado
    m.allChannels = invalid
    m.playlists = []
    m.currentPlaylist = 0
    m.isPlayingVideo = false
    m.overlayVisible = false
    
    ' Cargar listas guardadas
    loadSavedPlaylists()
    
    ' Mostrar menú de listas
    setupPlaylistMenu()
    
    ' Cargar playlist por defecto
    if m.playlists.Count() > 0 then
        loadPlaylist(m.playlists[0].url)
    else
        showPlaylistManager()
    end if
End sub

' **************************************************************

function onKeyEvent(key as String, press as Boolean) as Boolean
    result = false
    
    if(press)
        if m.isPlayingVideo then
            ' Controles durante reproducción
            if(key = "back")
                ' Volver al menú principal (detener video)
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
                ' Mostrar/ocultar overlay de canales (video sigue)
                if m.overlayVisible then
                    ' Ocultar overlay
                    m.channelOverlay.visible = false
                    m.overlayVisible = false
                    m.video.SetFocus(true)
                else
                    ' Mostrar overlay con lista de canales
                    m.channelOverlay.visible = true
                    m.overlayVisible = true
                    ' Copiar contenido actual a overlay
                    m.channelOverlayList.content = m.allChannels
                    m.channelOverlayList.SetFocus(true)
                end if
                result = true
            else if(key = "right" and m.overlayVisible)
                ' Ocultar overlay si presiona derecha
                m.channelOverlay.visible = false
                m.overlayVisible = false
                m.video.SetFocus(true)
                result = true
            end if
        else
            ' Navegación en el menú
            if(key = "right")
                m.sidePanel.visible = true
                m.channelList.SetFocus(true)
                result = true
            else if(key = "left")
                m.sidePanel.visible = true
                m.playlistList.SetFocus(true)
                result = true
            else if(key = "options")
                showPlaylistManager()
                result = true
            end if
        end if
    end if
    
    return result 
end function


' ******** GESTIÓN DE PLAYLISTS ********

sub loadSavedPlaylists()
    ' Cargar playlists guardadas del registro
    reg = CreateObject("roRegistrySection", "playlists")
    m.playlists = []
    
    ' Agregar playlist por defecto
    defaultPlaylist = {
        name: "Colombia TV",
        url: "https://www.m3u.cl/lista/CO.m3u",
        isDefault: true
    }
    m.playlists.Push(defaultPlaylist)
    
    ' Cargar playlists adicionales del registro
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
    ' Guardar nueva playlist en el registro
    reg = CreateObject("roRegistrySection", "playlists")
    
    count = 0
    if reg.Exists("count") then
        count = reg.Read("count").ToInt()
    end if
    
    reg.Write("name_" + count.ToStr(), name)
    reg.Write("url_" + count.ToStr(), url)
    reg.Write("count", (count + 1).ToStr())
    reg.Flush()
    
    ' Agregar a la lista en memoria
    m.playlists.Push({name: name, url: url, isDefault: false})
    
    ' Recargar menú de listas
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
    ' Configurar el menú lateral solo con listas
    content = CreateObject("roSGNode", "ContentNode")
    
    ' Agregar listas guardadas
    for each playlist in m.playlists
        item = content.CreateChild("ContentNode")
        if playlist.isDefault = true then
            item.title = "⭐ " + playlist.name
        else
            item.title = "� " + playlist.name
        end if
    end for
    
    ' Botón para agregar nueva lista
    item = content.CreateChild("ContentNode")
    item.title = "➕ Agregar Lista"
    
    m.playlistList.content = content
    m.playlistList.SetFocus(true)
end sub

sub onPlaylistSelected()
    selectedIdx = m.playlistList.itemSelected
    
    ' Verificar si es el último item (Agregar Lista)
    if selectedIdx = m.playlists.Count() then
        showPlaylistManager()
    else if selectedIdx >= 0 and selectedIdx < m.playlists.Count() then
        ' Cargar la lista seleccionada
        loadPlaylist(m.playlists[selectedIdx].url)
        m.currentPlaylist = selectedIdx
    end if
end sub


sub showPlaylistManager()
    PRINT ">>> PLAYLIST MANAGER <<<"

    keyboarddialog = createObject("roSGNode", "KeyboardDialog")
    keyboarddialog.backgroundUri = "pkg:/images/rsgde_bg_hd.jpg"
    keyboarddialog.title = "AGREGAR NUEVA LISTA M3U"
    keyboarddialog.message = "Ingresa la URL de la lista M3U"

    keyboarddialog.buttons=["Agregar","Cancelar"]
    keyboarddialog.optionsDialog=true

    m.top.dialog = keyboarddialog
    m.top.dialog.text = ""
    m.top.dialog.keyboard.textEditBox.maxTextLength = 300

    keyboarddialog.observeFieldScoped("buttonSelected","onPlaylistManagerKeyPress")
end sub

sub onPlaylistManagerKeyPress()
    if m.top.dialog.buttonSelected = 0 then ' Agregar
        url = m.top.dialog.text
        ' Validar URL
        if not isValidUrl(url) then
            errorDialog = CreateObject("roSGNode", "Dialog")
            errorDialog.title = "Error"
            errorDialog.message = "Please enter a valid HTTP or HTTPS URL"
            m.top.dialog.close = true
            m.top.dialog = errorDialog
            return
        end if
        
        ' Pedir nombre de la lista
        nameDialog = createObject("roSGNode", "KeyboardDialog")
        nameDialog.backgroundUri = "pkg:/images/rsgde_bg_hd.jpg"
        nameDialog.title = "NOMBRE DE LA LISTA"
        nameDialog.buttons=["OK","Cancelar"]
        m.top.dialog.close = true
        m.top.dialog = nameDialog
        
        ' Guardar URL temporalmente
        m.tempPlaylistUrl = url
        
        nameDialog.observeFieldScoped("buttonSelected","onPlaylistNameEntered")
    else
        m.top.dialog.close = true
    end if
end sub

sub onPlaylistNameEntered()
    if m.top.dialog.buttonSelected = 0 then ' OK
        name = m.top.dialog.text
        if name = "" or name = invalid then
            name = "Mi Lista"
        end if
        
        ' Guardar playlist
        if m.tempPlaylistUrl <> invalid then
            savePlaylist(name, m.tempPlaylistUrl)
            loadPlaylist(m.tempPlaylistUrl)
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
    ' Ocultar indicador de carga
    if m.loadingSpinner <> invalid then
        m.loadingSpinner.visible = false
    end if
    
    if m.get_channel_list.content <> invalid then
        ' Guardar todos los canales
        m.allChannels = m.get_channel_list.content
        
        ' Mostrar en lista simple (como antes)
        m.channelList.content = m.allChannels
        m.channelList.SetFocus(true)
    else
        ' Mostrar error si no hay contenido
        errorDialog = CreateObject("roSGNode", "Dialog")
        errorDialog.title = "Error"
        errorDialog.message = "No se pudo cargar la lista. Verifica la URL."
        m.top.dialog = errorDialog
    end if
end sub

sub onChannelSelected()
    ' Usuario seleccionó un canal de la lista principal
    selectChannelFromList(m.channelList)
end sub

sub onOverlayChannelSelected()
    ' Usuario seleccionó un canal del overlay (durante reproducción)
    selectChannelFromList(m.channelOverlayList)
    ' Ocultar overlay después de seleccionar
    m.channelOverlay.visible = false
    m.overlayVisible = false
end sub

sub selectChannelFromList(list as Object)
    ' Función común para seleccionar canal de cualquier lista
    if list.content = invalid or list.content.getChildCount() = 0 then
        return
    end if
    
    ' Verificar si hay grupos (secciones)
    firstChild = list.content.getChild(0)
    if firstChild = invalid then return
    
    content = invalid
    
    if firstChild.getChildCount() = 0 then
        ' No hay grupos, selección directa
        content = list.content.getChild(list.itemSelected)
    else
        ' Hay grupos, calcular el item correcto
        itemSelected = list.itemSelected
        for i = 0 to list.currFocusSection - 1
            itemSelected = itemSelected - list.content.getChild(i).getChildCount()
        end for
        sectionContent = list.content.getChild(list.currFocusSection)
        if sectionContent = invalid then return
        content = sectionContent.getChild(itemSelected)
    end if
    
    if content = invalid then return
    
    playChannel(content)
end sub

sub playChannel(content as Object)
    'Probably would be good to make content = content.clone(true) but for now it works like this
	content.streamFormat = "hls, mp4, mkv, mp3, avi, m4v, ts, mpeg-4, flv, vob, ogg, ogv, webm, mov, wmv, asf, amv, mpg, mp2, mpeg, mpe, mpv, mpeg2"

	if m.video.content <> invalid and m.video.content.url = content.url then return

	content.HttpSendClientCertificates = true
	content.HttpCertificatesFile = "common:/certs/ca-bundle.crt"
	m.video.EnableCookies()
	m.video.SetCertificatesFile("common:/certs/ca-bundle.crt")
	m.video.InitClientCertificates()

	m.video.content = content

	m.top.backgroundURI = "pkg:/images/rsgde_bg_hd.jpg"
	m.video.trickplaybarvisibilityauto = false
	
	' Mostrar video en pantalla COMPLETA (1920x1080)
	m.video.visible = true
	m.video.translation = [0, 0]
	m.video.width = 1920
	m.video.height = 1080
	
	' Ocultar todos los menús
	m.channelList.visible = false
	m.sidePanel.visible = false
	m.channelOverlay.visible = false
	
	' Estado
	m.isPlayingVideo = true
	m.overlayVisible = false
	m.video.SetFocus(true)

	m.video.control = "play"
end sub


' Validar si la URL es válida
function isValidUrl(url as String) as Boolean
    if url = "" then return false
    
    ' Validar que comience con http:// o https://
    httpReg = CreateObject("roRegex", "^https?://", "i")
    if not httpReg.isMatch(url) then return false
    
    ' Validar formato básico de URL
    urlReg = CreateObject("roRegex", "^https?://[^\s/$.?#].[^\s]*$", "i")
    return urlReg.isMatch(url)
end function
