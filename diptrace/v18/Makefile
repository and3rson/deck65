SOURCES := Top.gbr Bot.gbr TopMask.gbr BotMask.gbr TopSilk.gbr BotSilk.gbr Board.gbr DrillPlated.drl MillPlated.drl

v18.zip: $(SOURCES)
	rm -f v18.zip
	zip -r v18.zip $(SOURCES)

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
	rm *.gbr *.drl v18.zip

.PHONY: view
view:
	gerbview $(SOURCES)
