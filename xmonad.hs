import XMonad
import XMonad.Config.Gnome

-- I love terminators
config_terminal = "terminator"

main = xmonad gnomeConfig
	{
          terminal = config_terminal,
          modMask = mod4Mask,
          manageHook = manageHook gnomeConfig
                       <+>
                       (className =? "Do" --> doIgnore)
	}
