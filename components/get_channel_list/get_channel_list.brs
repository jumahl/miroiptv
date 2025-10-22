sub init()
	m.top.functionName = "getContent"
end sub

sub getContent()
	feedurl = m.global.feedurl

	m.port = CreateObject ("roMessagePort")
	searchRequest = CreateObject("roUrlTransfer")
	searchRequest.setURL(feedurl)
	searchRequest.SetPort(m.port)
	searchRequest.EnableEncodings(true)
	httpsReg = CreateObject("roRegex", "^https:", "")
	if httpsReg.isMatch(feedurl)
		searchRequest.SetCertificatesFile ("common:/certs/ca-bundle.crt")
		searchRequest.AddHeader ("X-Roku-Reserved-Dev-Id", "")
		searchRequest.InitClientCertificates ()
	end if

	if searchRequest.AsyncGetToString()
		event = wait(60000, m.port)
		if type(event) = "roUrlEvent"
			responseCode = event.GetResponseCode()
			if responseCode = 200
				text = event.GetString()
				if text = "" or text = invalid then
					print "Playlist vacío o inválido"
					m.top.content = CreateObject("roSGNode", "ContentNode")
					return
				end if
			else
				print "Error HTTP: "; responseCode
				m.top.content = CreateObject("roSGNode", "ContentNode")
				return
			end if
		else
			print "Timeout al obtener el playlist"
			m.top.content = CreateObject("roSGNode", "ContentNode")
			return
		end if
	else
		print "Error al iniciar la petición HTTP"
		m.top.content = CreateObject("roSGNode", "ContentNode")
		return
	end if

	reHasGroups = CreateObject("roRegex", "group-title\=" + chr(34) + "?([^" + chr(34) + "]*)"+chr(34)+"?,","")
	hasGroups = reHasGroups.isMatch(text)
	print hasGroups

	reTvgLogo = CreateObject("roRegex", "tvg-logo\=" + chr(34) + "([^" + chr(34) + "]*)" + chr(34), "i")

	reLineSplit = CreateObject ("roRegex", "(?>\r\n|[\r\n])", "")
	reExtinf = CreateObject ("roRegex", "(?i)^#EXTINF:\s*(\d+|-1|-0).*,\s*(.*)$", "")

	rePath = CreateObject ("roRegex", "^([^#].*)$", "")
	inExtinf = false
	con = CreateObject("roSGNode", "ContentNode")
	if not hasGroups
		group = con
	else
		groups = []
	end if

	logoUrl = ""
	channelCount = 0
	for each line in reLineSplit.Split (text)
		if inExtinf
			maPath = rePath.Match (line)
			if maPath.Count () = 2
				item = group.CreateChild("ContentNode")
				item.url = maPath [1]
				item.title = title
				if logoUrl <> "" and logoUrl <> invalid
					item.HDPosterUrl = logoUrl
					item.SDPosterUrl = logoUrl
				end if
				logoUrl = ""
				channelCount = channelCount + 1
				inExtinf = False
			end if
		end if
		maExtinf = reExtinf.Match (line)
		if maExtinf.Count () = 3
			if hasGroups
				maGroup = reHasGroups.Match(line)
				if maGroup.Count() >= 2 then
					groupName = maGroup[1]
					if groupName = "" or groupName = invalid then
						groupName = "Other"
					end if
					group = invalid
					for x = 0 to con.getChildCount()-1
						node = con.getChild(x)
						if node.id = groupName
							group = node
							exit for
						end if
					end for
					if group = invalid
						group = con.CreateChild("ContentNode")
						group.contenttype = "SECTION"
						group.title = groupName
						group.id = groupName
					end if
				else
					if group = invalid then group = con
				end if
			end if
			maLogo = reTvgLogo.Match(line)
			if maLogo.Count() = 2
				logoUrl = maLogo[1]
			end if
			length = maExtinf[1].ToInt ()
			if length < 0 then length = 0
			title = maExtinf[2]
			if title = "" or title = invalid then
				title = "Unknown Channel"
			end if
			inExtinf = True
		end if
	end for
	
	print "Total channels loaded: "; channelCount

	m.top.content = con
end sub
