require "/scripts/util.lua"
tagCaching={}
tagCaching.primaryTagCache={}
tagCaching.altTagCache={}
tagCaching.mergedCache={}
tagCaching.primaryTagCacheOld={}
tagCaching.altTagCacheOld={}
tagCaching.mergedTagCacheOld={}

function tagCaching.update()
	local primaryItem=world.entityHandItem(entity.id(), "primary") --check what they have in hand
	local primaryItemDescriptor=world.entityHandItemDescriptor(entity.id(), "primary") --check what they have in hand
	local altItem=world.entityHandItem(entity.id(), "alt")
	local altItemDescriptor=world.entityHandItemDescriptor(entity.id(), "alt")
	local doMerge=false

	--these are set for one update only, so that any dependent scripts can check if something has changed.
	if tagCaching.primaryTagCacheItemChanged then
		tagCaching.primaryTagCacheItemChanged=false
		tagCaching.primaryTagCacheOld={}
	end
	if tagCaching.altTagCacheItemChanged then
		tagCaching.altTagCacheItemChanged=false
		tagCaching.altTagCacheOld={}
	end
	if tagCaching.mergedTagCacheChanged then
		tagCaching.mergedTagCacheChanged=false
		tagCaching.mergedTagCacheOld={}
	end

	if tagCaching.primaryTagCacheItem~=primaryItem then
		tagCaching.primaryTagCacheOld=copy(tagCaching.primaryTagCache)
		local pass,result=pcall(root.itemConfig,primaryItemDescriptor)
		tagCaching.primaryTagCache=tagCaching.tagsToKeys(tagCaching.fetchTags(pass and result))
		if pass and result then
			local dummy=nil
			if (result.parameters and result.parameters.twoHanded~=nil) then
				dummy=result.parameters.twoHanded
			elseif (result.config and result.config.twoHanded~=nil) then
				dummy=result.config.twoHanded
			end
			if dummy ~= nil then
				tagCaching.primaryTagCache.twoHanded=dummy
				tagCaching.primaryTagCache.oneHanded=not dummy
			end
		end
		tagCaching.primaryTagCacheItem=primaryItem
		tagCaching.primaryTagCacheItemChanged=true
		doMerge=true
	end
	if tagCaching.altTagCacheItem~=altItem then
		tagCaching.altTagCacheOld=copy(tagCaching.altTagCache)
		local pass,result=pcall(root.itemConfig,altItemDescriptor)
		tagCaching.altTagCache=tagCaching.tagsToKeys(tagCaching.fetchTags(pass and result))
		if pass and result then
			local dummy=nil
			if (result.parameters and result.parameters.twoHanded~=nil) then
				dummy=result.parameters.twoHanded
			elseif (result.config and result.config.twoHanded~=nil) then
				dummy=result.config.twoHanded
			end
			if dummy ~= nil then
				tagCaching.altTagCache.twoHanded=dummy
				tagCaching.altTagCache.oneHanded=not dummy
			end
		end
		tagCaching.altTagCacheItem=altItem
		tagCaching.altTagCacheItemChanged=true
		doMerge=true
	end
	if doMerge then
		tagCaching.mergedCacheOld=copy(tagCaching.mergedCache)
		tagCaching.mergedCache={}
		for k,v in pairs(tagCaching.primaryTagCache or {}) do
			tagCaching.mergedCache[k]=v
		end
		for k,v in pairs(tagCaching.altTagCache or {}) do
			tagCaching.mergedCache[k]=v
		end
		tagCaching.mergedTagCacheChanged=true
	end
end

--this function fetches tags for the weapon, parameters if there, otherwise config. category and element are also taken, to same effect, and merged into tags.
function tagCaching.fetchTags(iConf,slimMode)
    if not iConf or not iConf.config then return {} end
    local tags={}
	local category
	local elementaltype
    for k,v in pairs(iConf.config or {}) do
		local kL=string.lower(k)
        if kL=="itemtags" then
			tags=v
		elseif kL=="category" then
			category=v
		elseif kL=="elementaltype" then
			elementaltype=v
        end
    end
    for k,v in pairs(iConf.parameters or {}) do
		local kL=string.lower(k)
        if kL=="itemtags" then
			tags=v
		elseif kL=="category" then
			category=v
		elseif kL=="elementaltype" then
			elementaltype=v
        end
    end
	if not slimMode then
		if category then table.insert(tags,category) end
		if elementaltype then table.insert(tags,elementaltype) end
	end
    return tags
end

--all tags are forcibly lowercase. this function makes it so. it also changes a list of tags to pairs of tag:true.
function tagCaching.tagsToKeys(tags)
    local buffer={}
    for _,v in pairs(tags) do
        buffer[v:lower()]=true
    end
    return buffer
end

function tagCaching.itemHasTag(item,tag,slimMode)
	local tagData=tagCaching.fetchTags(item,slimMode)
	for _,v in pairs(tagData) do
		if string.lower(v)==string.lower(tag) then
			return true
		end
	end
	return false
end
