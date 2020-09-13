# Base-Shell-Scripts
Collection of various shell scripts

All config options are in `GlobalNeeds`

# Color and Background scripts
There are a few scripts that I use to customize the look
of my machine.

I use the current background to set the
color scheme, using `generateColorPalette` to achieve this.

I use `setBackground` to grab a random image from the
Wallpaper directory and set it as the background.

## generateColorPalette

Shifts through image files in the Wallpaper directory and
genertes a pallette of up to 8 unique colors. This colors
are sorted from dark to light tones

## setBackground

Sets a random image from the Wallpaper directory as the
background image, as well as changinf the color scheme to
the scheme of the new background image

Within this scrip I also set the contents of the firefox
them file used by DynamicTheme addon

https://github.com/Tutadit/DynamicTheme-FirefoxAddon

## getPallete

A little API to get the color pallete as named constants
