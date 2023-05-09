SOURCES := Top.gbr Bot.gbr TopMask.gbr BotMask.gbr TopSilk.gbr BotSilk.gbr Board.gbr DrillPlated.drl MillPlated.drl

v16.zip: $(SOURCES)
	rm -f v16.zip
	zip -r v16.zip $(SOURCES)

.PHONY: clean
clean:
	rm *.gbr *.drl v16.zip
