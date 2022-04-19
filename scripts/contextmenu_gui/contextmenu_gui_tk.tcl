#################################################################
## Context menu constructed via CLI args.                      ##
## Origin_ Avi Halachmi https://github.com/avih                ##
## Extension_ Thomas Carmichael https://gitlab.com/carmanaught ##
#################################################################
## mpv的tcl图形菜单的附属脚本 (3)/(3)

# Required when launching via tclsh, no-op when launching via wish
package require Tk
# Set the default (fallback) font, which probably won't be used unless the calling script
# doesn't actually provide a value
font create defFont -family "宋体" -size 10
option add *font defFont

# Remove the main window from the host window manager
wm withdraw .

set argList [split [lindex $argv 0] \x1f]

if { $::argc < 1 } {
    puts "Usage: context.tcl x y \"base menu name\" (4 x \"\") .. \"sets of 7 args\""
    exit 1
}

# Construct the menu from argv:
# - argv is one large block of values separated by the ASCII unit separator. The purpose
#   for this is due to the limitations of mpv's mp.utils.subprocess only accepting 256
#   arguments.
# - The first set of values contains the absolute x, y menu position, or under the
#   mouse if -1, -1, as well as the base menu name. Two question mark ("?") separated
#   values may also be provided to indicate a menu rebuild opening specific (sub)menus
# - The rest of the sets are detailed below (mVal items). The return-value for menu items
#   should be a number (the index of the item on the menu), and -1 is reserved for cancel.

set RESP_CANCEL -1

# Checkbutton/Radiobutton text values here to use in place of Tk checkbutton/radiobutton
# since the styling doesn't seem to show for the tk_popup, except when checked. It's
# important that a monospace font is used for the menu items to appear correctly.
set boxCheck "\[V\] "
set boxUncheck "\[ \] "
set radioSelect "(V) "
set radioEmpty "( ) "
set boxA "\[A\] "
set boxB "\[B\] "
# An empty prefix label that is spaces that count to the the same number of characters as
# the button labels
set emptyPre "    "
# This is to put a bit of a spacer between label and accelerator
set accelSpacer "   "
set menuWidth 36
# Various other global variables
set labelPre ""
set first 1
set postMenu "false"
set postMenus ""
set postIndexes ""
set errorValue "errorValue"
array set maxAccel {}
array set mVal {}

# To make the accelerator appear as if they're justified to the right, we iterate through
# the entire list and set the maximum accelerator length for each menu ($mVal(1)) after
# checking if a value exists first and then increasing the max value if the length of an
# item is greater than a previous max length value.
foreach {mVal(1) mVal(2) mVal(3) mVal(4) mVal(5) mVal(6) mVal(7)} $argList {
    if {$mVal(1) != "changemenu" || $mVal(1) != "cascade"} {
        if {![info exists ::maxAccel($mVal(1))]} {
            set ::maxAccel($mVal(1)) [string length $mVal(5)]
        } else {
            if {[string length $mVal(5)] > $::maxAccel($mVal(1))} {
                set ::maxAccel($mVal(1)) [string length $mVal(5)]
            }
        }
    }
}

# We call this when creating the accelerator labels, passing the current menu ($mVal(1))
# and the accelerator, getting the max length for that menu and adding 4 spaces, then
# appending the label after the spaces, making it appear justified to the right.
proc makeLabel {curTable accelLabel} {
    set spacesCount [expr [expr $::maxAccel($curTable) + 4] - [string length $accelLabel]]
    set whiteSpace [string repeat " " $spacesCount]
    set fullLabel $whiteSpace$accelLabel
    return $fullLabel
}

# The assumed values for most iterations are:
# mVal(1) = Table Name
# mVal(2) = Table Index
# mVal(3) = Item Type
# mVal(4) = Item Label
# mVal(5) = Item Accelerator/Shortcut
# mVal(6) = Item State (Check/Unchecked, etc)
# mVal(7) = Item Disable (True/False)
foreach {mVal(1) mVal(2) mVal(3) mVal(4) mVal(5) mVal(6) mVal(7)} $argList {
    if {$first} {
        set pos_x $mVal(1)
        set pos_y $mVal(2)
        set baseMenuName $mVal(3)
        set baseMenu [menu .$baseMenuName -tearoff 0]
        set curMenu .$mVal(3)
        set preMenu .$mVal(3)
        if {$mVal(4) != ""} {
            set postMenu "true"
            set postMenus $mVal(4)
            set postIndexes $mVal(5)
        }
        if {$mVal(6) != ""} {
            font configure defFont -family "$mVal(6)"
        }
        if {$mVal(7) != ""} {
            font configure defFont -size $mVal(7)
        }
        set first 0
        continue
    }

    if {$mVal(1) != "changemenu"} {
        if {$mVal(7) == "false"} {
            set mVal(7) "normal"
        } elseif {$mVal(7) == "true"} {
            set mVal(7) "disabled"
        } else {
            set mVal(7) "normal"
        }
    }

    if {$mVal(1) == "changemenu"} {
        set changeCount 0
        set menuLength 0
        set mCheck ""
        set arrSize [array size mVal]
        # Check how many empty values are in the list and increase the $changeCount variable to
        # subtract that value from the size of the array of values (currently 7), giving the
        # total number of values that have actually been passed, which is how many times we'll
        # increment through to set our menu values.
        for {set i 2} {$i <= $arrSize} {incr i} {
            if {$mVal($i) == ""} { set changeCount [expr $changeCount + 1] }
        }
        set menuLength [expr $arrSize - $changeCount]
        # We're going to assume that the right-most value that isn't "" of the foreach variables
        # when doing a menu change is the highest level of menu and that there's been no gaps of
        # "" values (which there shouldn't be).
        for {set i 2} {$i <= $menuLength} {incr i} {
            if {$i == 2} {
                set mCheck .$mVal($i)
                set preMenu $mCheck
                set curMenu $mCheck
            } else {
                set preMenu $mCheck
                set mCheck $mCheck.$mVal($i)
                set curMenu $mCheck
            }
            if {![winfo exists $mCheck]} {
                menu $mCheck -tearoff 0
            }
        }
        continue
    }

    if {$mVal(1) == "cascade"} {
        # Reverse the $curMenu and $preMenu here so that the menu so that it attaches in the
        # correct order.
        $preMenu add cascade -label $emptyPre$mVal(2) -state $mVal(7) -menu $curMenu
        continue
    }

    if {$mVal(3) == "separator"} {
        $curMenu add separator
        continue
    }

    if {$mVal(3) == "command"} {
        $curMenu add command -label $emptyPre$mVal(4) -accel [makeLabel $mVal(1) $mVal(5)] -state $mVal(7) -command "done $mVal(1) $mVal(2) $curMenu"
        continue
    }

    # The checkbutton/radiobutton items are just 'add command' items with a label prefix to
    # give a textual appearance of check/radio items showing their status.

    if {$mVal(3) == "checkbutton"} {
        if {$mVal(6) == "true"} {
            set labelPre $boxCheck
        } else {
            set labelPre $boxUncheck
        }

        $curMenu add command -label $labelPre$mVal(4) -accel [makeLabel $mVal(1) $mVal(5)] -state $mVal(7) -command "done $mVal(1) $mVal(2) $curMenu"
        continue
    }

    if {$mVal(3) == "radiobutton"} {
        if {$mVal(6) == "true"} {
            set labelPre $radioSelect
        } else {
            set labelPre $radioEmpty
        }

        $curMenu add command -label $labelPre$mVal(4) -accel [makeLabel $mVal(1) $mVal(5)] -state $mVal(7) -command "done $mVal(1) $mVal(2) $curMenu"
        continue
    }

    if {$mVal(3) == "ab-button"} {
        if {$mVal(6) == "a"} {
            set labelPre $boxA
        } elseif {$mVal(6) == "b"} {
            set labelPre $boxB
        } elseif {$mVal(6) == "off"} {
            set labelPre $boxUncheck
        }

        $curMenu add command -label $labelPre$mVal(4) -accel [makeLabel $mVal(1) $mVal(5)] -state $mVal(7) -command "done $mVal(1) $mVal(2) $curMenu"
        continue
    }
}

# Read the absolute mouse pointer position if we're not given a pos via argv
if {$pos_x == -1 && $pos_y == -1} {
    set pos_x [winfo pointerx .]
    set pos_y [winfo pointery .]
}

# On item-click/menu-dismissed, we print a json object to stdout with values to be
# used in the menu engine
proc done {menuName index menuPath} {
    puts "{\"x\":\"$::pos_x\", \"y\":\"$::pos_y\", \"menuname\":\"$menuName\", \"index\":\"$index\", \"menupath\":\"$menuPath\", \"errorvalue\":\"$::errorValue\"}"
    exit
}

# Seemingly, on both windows and linux, "cancelled" is reached after the click but
# before the menu command is executed and _a_sync to it. Therefore we wait a bit to
# allow the menu command to execute first (and exit), and if it didn't, we exit here.
proc cancelled {} {
    after 100 {done $baseMenuName $::RESP_CANCEL $baseMenuName}
}

# Calculate the menu position relative to the Tk window
set win_x [expr {$pos_x - [winfo rootx .]}]
set win_y [expr {$pos_y - [winfo rooty .]}]

# Launch the popup menu
tk_popup $baseMenu $win_x $win_y
# Use after idle and check if the 'post' menu check is true and do a postcascade on the
# relevant menus to have the menu pop back up, with the cascade in the same place.
# Note: This doesn't work on Windows, as per the comment below regarding tk_popup being
#       synchronous and will only run after the menu is closed.
after idle {
    if {$postMenu == "true"} {
        set menuArgs [split $postMenus "?"]
        set indexArgs [split $postIndexes "?"]
        for {set i 0} {$i < [llength $indexArgs]} {incr i} {
            [lindex $menuArgs $i] postcascade [lindex $indexArgs $i]
        }
    }
}

# On Windows tk_popup is synchronous and so we exit when it closes, but on Linux
# it's async and so we need to bind to the <Unmap> event (<Destroyed> or
# <FocusOut> don't work as expected, e.g. when clicking elsewhere even if the
# popup disappears. <Leave> works but it's an unexpected behavior for a menu).
# Note: If we don't catch the right event, we'd have a zombie process since no
#       window. Equally important - the script will not exit.
# Note: Untested on macOS (macports' tk requires xorg. meh).
if {$tcl_platform(platform) == "windows"} {
    cancelled
} else {
    bind $baseMenu <Unmap> cancelled
}
