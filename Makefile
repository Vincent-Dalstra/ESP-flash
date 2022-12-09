SHELL = /bin/sh


prj := JLCPCB_2_Layer
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



ass-opts := --missingError --assembly 
ass-opts += --field LCSC --ignore JLCPCB_IGNORE --corrections JLCPCB_CORRECTION


# All: creates everything needed for fabrication.
.PHONY: all 
all: gerbers.zip ${out}/bom.csv ${out}/pos.csv

# clean: Deletes all generated files.
.PHONY: clean
clean:
	rm -r ${out}/*

# Trim: Removes extraneous files; useful when packaging into release directory.
.PHONY: trim
trim:
	rm -r ${gout}

gerbers.zip : ${board-files}
	zip ${out}/gerbers.zip ${out}/gerber/*


# Create the Gerbers; checking for DRC ERRORS (not warning though) before we make it
${board-files}&: ${prj}.kicad_pcb
	kikit drc run ${prj}.kicad_pcb && kikit export gerber ${prj}.kicad_pcb ${out}/gerber/

# The Bill-of-materials is based on every schematic combined. The Position file is based on
# the pcb. Both are generated in a single command; hence the combined-target recipe.
${out}/bom.csv ${out}/pos.csv&: *.kicad_sch ${prj}.kicad_pcb
	kikit fab jlcpcb ${ass-opts} --schematic ${prj}.kicad_sch ${prj}.kicad_pcb ${out}/



