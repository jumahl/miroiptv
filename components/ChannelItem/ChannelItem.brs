sub init()
    m.itemPoster = m.top.findNode("itemPoster")
    m.itemTitle = m.top.findNode("itemTitle")
    m.focusIndicator = m.top.findNode("focusIndicator")
    m.itemBackground = m.top.findNode("itemBackground")
    
    ' Observar cambios
    m.top.observeField("itemContent", "showcontent")
    m.top.observeField("focusPercent", "showfocus")
end sub

sub showcontent()
    itemcontent = m.top.itemContent
    if itemcontent <> invalid then
        if itemcontent.title <> invalid then
            m.itemTitle.text = itemcontent.title
        else
            m.itemTitle.text = "Canal"
        end if
        
        ' Usar logo si existe, sino usar placeholder
        if itemcontent.HDPosterUrl <> invalid and itemcontent.HDPosterUrl <> "" then
            m.itemPoster.uri = itemcontent.HDPosterUrl
        else if itemcontent.SDPosterUrl <> invalid and itemcontent.SDPosterUrl <> "" then
            m.itemPoster.uri = itemcontent.SDPosterUrl
        else
            m.itemPoster.uri = "pkg:/images/channel_placeholder.png"
        end if
    end if
end sub

sub showfocus()
    scale = 1.0
    if m.top.focusPercent > 0.5 then
        scale = 1.05
        m.focusIndicator.opacity = 1.0
    else
        m.focusIndicator.opacity = 0.0
    end if
    
    m.top.scale = [scale, scale]
end sub
