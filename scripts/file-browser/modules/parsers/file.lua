
local msg = require 'mp.msg'
local utils = require 'mp.utils'

local API = require 'modules.utils'

--parser ofject for native filesystems
local file_parser = {
    name = "file",
    priority = 110,

    --as the default parser we'll always attempt to use it if all others fail
    can_parse = function(_, directory) return true end,

    --scans the given directory using the mp.utils.readdir function
    parse = function(self, directory)
        local new_list = {}
        local list1 = utils.readdir(directory, 'dirs')
        if list1 == nil then return nil end

        --sorts folders and formats them into the list of directories
        for i=1, #list1 do
            local item = list1[i]

            --filters hidden dot directories for linux
            if self.valid_dir(item) then
                msg.trace(item..'/')
                table.insert(new_list, {name = item..'/', type = 'dir'})
            end
        end

        --appends files to the list of directory items
        local list2 = utils.readdir(directory, 'files')
        for i=1, #list2 do
            local item = list2[i]

            --only adds whitelisted files to the browser
            if self.valid_file(item) then
                msg.trace(item)
                table.insert(new_list, {name = item, type = 'file'})
            end
        end
        return API.sort(new_list), {filtered = true, sorted = true}
    end
}

return file_parser
