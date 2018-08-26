-- Example Usage: lua doc.lua source.lua output.md

local tagTypes = {
    builtin = "@",
    customSection = "$",
    customField = "&",
}
tagTypeClass = tagTypes.builtin .. tagTypes.customSection .. tagTypes.customField

local sectionTags = {
    ["module"] = true,
    ["class"] = true,
    ["function"] = true,
    ["table"] = true,
}

local function splitName(name)
    local ret = {}
    for part in string.gmatch(name, "[^.:]+") do
        table.insert(ret, part)
    end
    return ret
end

local function addSection(doc, tag, name, isCustom)
    local section = {
        tag = tag,
        name = name,
        namePath = splitName(name),
        isCustom = isCustom,
    }
    table.insert(doc, section)
    return section
end

local function paramTable(str)
    local ident = str:match("(%S+)")
    if not ident then
        error(("Could not parse param/field tag '%s'"):format(str))
    end
    local _ident, desc = str:match("(%S+)%s+(.*)$")
    if _ident and desc then
        return {name = _ident, description = desc}
    else
        return {name = ident}
    end
end

local function addField(section, tag, content, isCustom)
    if section == nil then
        error("Field tag does not have a section")
    end

    local item = {
        tag = tag,
        content = content,
        isCustom = isCustom or false,
    }

    if tag == "param" then
        if not section.params then section.params = {} end
        table.insert(section.params, paramTable(content))
    elseif tag == "field" then
        if not section.fields then section.fields = {} end
        table.insert(section.fields, paramTable(content))
    elseif tag == "return" then
        section.returnValue = content
    elseif tag == "desc" then
        if section.description then
            section.description = section.description .. "\n" .. content
        else
            section.description = content
        end
    elseif tag == "see" then
        if not section.see then section.see = {} end
        table.insert(section.see, content)
    elseif tag == "usage" then
        if section.usage then
            section.usage = section.usage .. "\n" .. content
        elseif content:len() > 0 then
            section.usage = content
        end
    elseif isCustom then
        if not section.custom then section.custom = {} end
        table.insert(section.custom, {tag = tag, content = content})
    else
        error("Unknown field tag: " .. tag)
    end
end

local function parseDoc(path)
    print("reading", path)
    io.input(path)

    local doc = {}
    local currentSection = nil
    local lastTag = nil

    while true do
        local line = io.read("*line")
        if not line then break end
        local tagType, tag, content = line:match("^%s*%-%-%-?%s*([".. tagTypeClass .. "])([a-zA-Z]*)%s?(.*)$")
        if tagType and tag and content then
            if tag:len() == 0 then
                if not lastTag then
                    error("Cannot use repeat tag before any tag was used.")
                end
                tag = lastTag
            end
            lastTag = tag

            if tagType == tagTypes.builtin then
                if sectionTags[tag] then
                    currentSection = addSection(doc, tag, content)
                else
                    addField(currentSection, tag, content, true)
                end
            elseif tagType == tagTypes.customSection then
                currentSection = addSection(doc, tag, content)
            elseif tagType == tagTypes.customField then
                addField(currentSection, tag, content, true)
            else
                error("Unknown tag type: " .. tagType)
            end
        end
    end

    return doc
end

local function getLink(name)
    return name:lower():gsub("[^%w ]", ""):gsub(" ", "-")
end

local function emitParamMd(list)
    for _, elem in ipairs(list) do
        if elem.description then
            io.write(("- *%s*: %s\n"):format(elem.name, elem.description))
        else
            io.write(("- *%s*\n"):format(elem.name))
        end
    end
    io.write("\n")
end

local function emitMarkdown(doc, path)
    io.output(path)
    print("writing", path)

    for _, section in ipairs(doc) do
        local heading = ""
        for i = 1, #section.namePath do
            heading = heading .. "#"
        end
        io.write(heading .. " " .. section.name .. "\n\n")
        io.write(("*[%s]*\n\n"):format(section.tag))

        if section.description then
            io.write(section.description .. "\n\n")
        end

        if section.tag == "module" then
            -- do nothing special
        elseif section.tag == "class" then
            if section.params and #section.params > 0 then
                io.write("**Constructor Arguments**:\n")
                emitParamMd(section.params)
            end
            if section.fields and #section.fields > 0 then
                io.write("**Member variables**:\n")
                emitParamMd(section.fields)
            end
        elseif section.tag == "function" then
            if section.params and #section.params > 0 then
                io.write("**Parameters**:\n")
                emitParamMd(section.params)
            end
            if section.returnValue then
                io.write("**Return Value**: " .. section.returnValue .. "\n\n")
            end
        elseif section.tag == "table" then
            if section.fields and #section.fields > 0 then
                io.write("**Fields**:\n")
                emitParamMd(section.fields)
            end
        end

        if section.usage then
            io.write("**Usage**:\n```lua\n" .. section.usage .. "\n```\n\n")
        end

        if section.see then
            local links = {}
            for _, other in ipairs(section.see) do
                table.insert(links, ("[%s](#%s)"):format(other, getLink(other)))
            end
            io.write("**See also**: " .. table.concat(links, ", ") .. "\n")
        end
    end
end

local success, inspect = pcall(require, "inspect")
inspect = success and inspect

local doc = parseDoc(arg[1])
if inspect then
    print(inspect(doc))
end
emitMarkdown(doc, arg[2])

