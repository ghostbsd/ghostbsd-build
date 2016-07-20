A $flavour means to be a desktop environmnet such 
as: KDE, Gnome, Mate, XFCE or even nox ( no X which means pure freebsd ghostbsd configured)

 ghostbsd-build/packages directory structure:
1) a $flavour file 
2) packages.d subdir for freebsd packages includes from deps section of 
ghostbsd-build/packages/$flavour file 
3) ghostbsd.d subdir for ghostbsd ports/packages includes  from 
ghostbsd_deps section of ghostbsd-build/packages/$flavour file
4) packages.cfg subdir for freebsd packages that needs special configuration 
after installing 

1)
Please don't change $flavour file structure because build scripts won't work
$flavour file is structured as :

desc = """
brief description of $flavour
"""
deps = """
$flavour depends/includes from packages.d files
"""
packages = """
unused now
"""
ghostbsd_deps="""
$flavour depends/includes from ghostbsd.d ghostbsd files/ports
"""

2) packages.d subdir contains files structured by some criteria such 
as: internet, print, office , sound-video, graphic, DE (kDE files , mate files ..), xorg
each file from packages.d is structured as:
