PLIST_NAME := com.claude.obsidian-sync.plist
PLIST_SRC  := $(CURDIR)/launchagents/$(PLIST_NAME)
PLIST_DST  := $(HOME)/Library/LaunchAgents/$(PLIST_NAME)

.PHONY: sync-start sync-stop sync-status

sync-start: $(PLIST_SRC)
	cp $(PLIST_SRC) $(PLIST_DST)
	launchctl load $(PLIST_DST)
	@echo "Started obsidian-sync"

sync-stop:
	-launchctl unload $(PLIST_DST) 2>/dev/null
	-rm -f $(PLIST_DST)
	@echo "Stopped obsidian-sync"

sync-status:
	@if launchctl list | grep -q com.claude.obsidian-sync; then \
		echo "Running"; \
	else \
		echo "Stopped"; \
	fi
