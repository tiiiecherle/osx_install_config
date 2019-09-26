#!/usr/bin/env python

# script and all credits
# https://gist.github.com/korylprince/be2e09e049d2fd721ce769770d983850#file-overwrite-py
# revision 3 from 18 Sep 2018

"""
Overwrites server favorites with servers.
Run as root to update all users or as normal user to update just that user.
"""

import os
import getpass
import subprocess
import uuid

import Foundation

favorites_path = "/Users/{user}/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.FavoriteServers.sfl2"

# Use a tuple: ("<name>", "<path>") to set a name for the favorite.
# Otherwise just use a string and the path will be used as the name
#servers = (("My Name", "smb://server.example.com/share"), "vnc://server.example.com")
#servers = ("smb://192.168.1.xyz",)


###

def import_server_variable():

    # python3 compatibility by setting unicode = str
    import sys
    if sys.version_info[0] >= 3:
        unicode = str
        
    # getting logged in user
    global username
    #import getpass
    #user = getpass.getuser()
    # or (see loggedInUser in shell scripts)
    from SystemConfiguration import SCDynamicStoreCopyConsoleUser
    import sys
    username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]
    #print (username)
    
    # defining path to script with server variable
    from os.path import dirname as up
    three_up = up(up(up(__file__)))
    #print (three_up)
    path = (three_up) + "/_scripts_input_keep/finder_favorites.py"
    #path = (three_up) + "/_scripts_input_keep/finder_favorites_" + username + ".py"
    
    # checking if file exists
    import os
    if not os.path.exists(path):
        print("file " + path + " does not exists, exiting...")
        quit()
    
    # reading server variable
    def getVarFromFile(filename):
        import imp
        f = open(filename)
        global data
        data = imp.load_source('data', path)
        f.close()
    
    getVarFromFile(path)
    print ('')
    print("severs entry...")
    print (data.servers)
    global servers
    servers = (data.servers)
    
    # checking if server variable is defined
    try:
        servers
    except NameError:
        print("servers is not defined, exiting...")
        quit()
    else:
        print('')

import_server_variable()


###

def get_users():
    "Get users with a home directory in /Users"

    # get users from dscl
    dscl_users = subprocess.check_output(["/usr/bin/dscl", ".", "-list", "/Users"]).splitlines()

    # get home directories
    homedir_users = os.listdir("/Users")

    # return users that are in both lists
    users = set(dscl_users).intersection(set(homedir_users))
    return [u.strip() for u in users if u.strip() != ""]

def set_favorites(user, servers):
    "Set the Server Favorites for the given user"

    # generate necessary structures
    items = []
    for server in servers:
        name = server[0] if len(server) == 2 else server
        path = server[1] if len(server) == 2 else server
        item = {}
        # use unicode to translate to NSString
        item["Name"] = unicode(name)
        url = Foundation.NSURL.URLWithString_(unicode(path))
        bookmark, _ = url.bookmarkDataWithOptions_includingResourceValuesForKeys_relativeToURL_error_(0, None, None, None)
        item["Bookmark"] = bookmark
        # generate a new UUID for each server
        item["uuid"] = unicode(uuid.uuid1()).upper()
        item["visibility"] = 0
        item["CustomItemProperties"] = Foundation.NSDictionary.new()

        items.append(Foundation.NSDictionary.dictionaryWithDictionary_(item))

    data = Foundation.NSDictionary.dictionaryWithDictionary_({
        "items": Foundation.NSArray.arrayWithArray_(items),
        "properties": Foundation.NSDictionary.dictionaryWithDictionary_({"com.apple.LSSharedFileList.ForceTemplateIcons": False})
    })

    # write sfl2 file
    Foundation.NSKeyedArchiver.archiveRootObject_toFile_(data, favorites_path.format(user=user))

# loop through users and set favorites
if __name__ == "__main__":
    # if running as root, run for all users. Otherwise run for current user
    user = getpass.getuser()
    if user == "root":
        users = get_users()
    else:
        users = [user]

    for user in users:
        try:
            set_favorites(user, servers)
            # fix owner if ran as root
            if user == "root":
                os.system(("chown {user} " + favorites_path).format(user=user))
            print ("Server Favorites set for " + user)
        except Exception as e:
            # if there's an error, log it an continue on
            print ("Failed setting Server Favorites for {0}: {1}".format(user, str(e)))

    # kill sharedfilelistd process to reload file. Finder should be closed when this happens
    os.system("killall sharedfilelistd")
print ('')