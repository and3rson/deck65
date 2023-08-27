TARGET = v21.zip
SRC = 1\ -\ Top.gbr 2\ -\ Bottom.gbr TopSilk.gbr BottomSilk.gbr TopMask.gbr BottomMask.gbr Drill_Plated_Through.gbr BoardOutline.gbr

$(TARGET): $(SRC)
	zip -r $@ $(SRC)

.PHONY: view
view:
	gerbview $(SRC)
