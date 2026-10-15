# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright © 2026 Florian Marrero Liestmann <f.m.liestmann@fx-ttr.de>

GUIX := guix time-machine -C $(CURDIR)/channels-lock.scm --
PACKAGES := -e '(@ (guix-apparmor packages apparmor) libapparmor)' \
    -e '(@ (guix-apparmor packages apparmor) apparmor)' \
    -e '(@ (guix-apparmor packages dbus) dbus-apparmor)'
PROFILES := $(wildcard modules/guix-apparmor/profiles/*)

# Deny unix rules are only dropped from the fallback for older kernels
PROFILE_WARNINGS := grep -v "deny unix socket rule not enforced" | grep .

export GUILE_LOAD_PATH := $(CURDIR)/modules$(if $(GUILE_LOAD_PATH),:$(GUILE_LOAD_PATH))

.PHONY: check check-profiles lint update

check:
	$(GUIX) build -L $(CURDIR)/modules --dry-run $(PACKAGES)
	$(MAKE) check-profiles
	$(MAKE) lint

check-profiles:
	apparmor=$$($(GUIX) build -L $(CURDIR)/modules \
	    -e '(@ (guix-apparmor packages apparmor) apparmor)') && \
	for profile in $(PROFILES); do \
	    ! $$apparmor/sbin/apparmor_parser \
	        --config-file $$apparmor/etc/apparmor/parser.conf \
	        --base $$apparmor/etc/apparmor.d \
	        --skip-cache -QT --warn=all $$profile 2>&1 \
	        | $(PROFILE_WARNINGS) || exit 1; \
	done

lint:
	! $(GUIX) lint -L $(CURDIR)/modules --no-network -x input-labels \
	    $(PACKAGES) 2>&1 \
	    | grep -v '^;;;' | grep .

update:
	guix time-machine -C channels.scm -- \
	    describe -f channels > channels-lock.scm.new
	mv channels-lock.scm.new channels-lock.scm
