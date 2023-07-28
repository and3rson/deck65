SOURCES := Top.gbr Bot.gbr TopMask.gbr BotMask.gbr TopSilk.gbr BotSilk.gbr Board.gbr DrillPlated.drl MillPlated.drl

v20.zip: $(SOURCES)
	rm -f v20.zip
	zip -r v20.zip $(SOURCES)

Top.gbr: 1\ -\ Top.gbr
	cp "1 - Top.gbr" Top.gbr

Bot.gbr: 2\ -\ Bottom.gbr
	cp "2 - Bottom.gbr" Bot.gbr

BotMask.gbr: BottomMask.gbr
	cp BottomMask.gbr BotMask.gbr

BotSilk.gbr: BottomSilk.gbr
	cp BottomSilk.gbr BotSilk.gbr

Board.gbr: BoardOutline.gbr
	cp BoardOutline.gbr Board.gbr

.PHONY: clean
clean:
	rm *.gbr *.drl v20.zip

.PHONY: view
view:
	gerbview $(SOURCES)
