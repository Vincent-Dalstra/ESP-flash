SHELL = /bin/sh

prj := $(basename $(wildcard *.kicad_pro))
out := Fab-Out
gout := ${out}/gerber


board-files := ${gout}/${prj}-CuTop.gtl
board-files += ${gout}/${prj}-PasteTop.gtp
board-files += ${gout}/${prj}-SilkTop.gto
board-files += ${gout}/${prj}-MaskTop.gts
board-files += ${gout}/${prj}-CuBottom.gbl
board-files += ${gout}/${prj}-PasteBottom.gbo
board-files += ${gout}/${prj}-SilkBottom.gbo
board-files += ${gout}/${prj}-MaskBottom.gbs
board-files += ${gout}/${prj}-EdgeCuts.gm1
board-files += ${gout}/${prj}.drl
board-files += ${gout}/${prj}-drl_map.pdf


rendered-files := pinion/spec.json
rendered-files += pinion/rendered/front.png
rendered-files += pinion/rendered/back.png


ass-opts := --missingError --assembly
ass-opts += --field LCSC
ass-opts += --ignore JLCPCB_IGNORE
ass-opts += --corrections JLCPCB_CORRECTION


# All: creates everything needed for fabrication.
.PHONY: all 
all: ${prj}.zip ${out}/bom.csv ${out}/pos.csv

# clean: Deletes all generated files.
.PHONY: clean
clean:
	rm -r ${out}/*

# Trim: Removes extraneous files; useful when packaging into release directory.
.PHONY: trim
trim:
	rm -r ${gout}

${prj}.zip : ${board-files}
	zip ${out}/${prj}.zip ${out}/gerber/*


# Create the Gerbers; checking for DRC ERRORS (not warnings though) before we make it
${board-files}&: ${prj}.kicad_pcb
	kikit export gerber ${prj}.kicad_pcb ${out}/gerber/

# The Bill-of-materials is based on every schematic combined. The Position file is based on
# the pcb. Both are generated in a single command; hence the combined-target recipe.
${out}/bom.csv ${out}/pos.csv&: *.kicad_sch ${prj}.kicad_pcb
	kikit fab jlcpcb ${ass-opts} --schematic ${prj}.kicad_sch ${prj}.kicad_pcb ${out}/


# ----


# pinion: Interactive boardview
.PHONY: pinion view
pinion view&: pinion/plotted/spec.json
	pinion serve -b --directory pinion/plotted/
	
# 
pinion/plotted/spec.json: pinion/spec.yaml
	pinion generate plotted --board ${prj}.kicad_pcb --specification pinion/spec.yaml pinion/plotted --pack --libs ~/Documents/Electronics/Kicad-libraries/PcbDraw-Lib/KiCAD-base/



# pinion: Use rendered image instead (slower, but usually more accurate)
.PHONY: view-rendered
view-rendered: ${rendered-files}
	pinion serve -b --directory pinion/rendered/
	
# Renders the board image.
# - Only works if KiCAD isn't running!
# - Takes a LOT of CPU and time, so we decrease its process priority
${rendered-files}&: pinion/spec.yaml ${prj}.kicad_pcb
	pgrep kicad || nice -n5 pinion generate rendered --board ${prj}.kicad_pcb --specification pinion/spec.yaml pinion/rendered --pack --renderer raytrace


# Create a template .yaml file with all components & pins
.PHONY: pinion-template view-template
pinion-template view-template pinion/template&:
	pinion template -b puzzle-shield-ESP32.kicad_pcb -o pinion/template.yaml
