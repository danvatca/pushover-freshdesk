#
# Copyright (C) 2014, Dan Vatca <dan.vatca@gmail.com>
#  All rights reserved.
#   Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:
#
#  1. Redistributions of source code must retain the above copyright notice, this
#     list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
#  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
#  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

DESTDIR=
DEPLOY_TARGET=

all: pushover-freshdesk pushover-freshdesk-initscript

pushover-freshdesk: pushover-freshdesk.php
	php -l pushover-freshdesk.php
	install -m 755 pushover-freshdesk.php pushover-freshdesk

pushover-freshdesk-initscript: pushover-freshdesk-initscript.sh
	bash -n pushover-freshdesk-initscript.sh
	install -m 755 pushover-freshdesk-initscript.sh pushover-freshdesk-initscript

install: all
	mkdir -p $(DESTDIR)/usr/bin/
	mkdir -p $(DESTDIR)/etc/init.d/
	install -m 755 pushover-freshdesk-config.php $(DESTDIR)/usr/bin/pushover-freshdesk-config.php
	install -m 755 pushover-freshdesk $(DESTDIR)/usr/bin/pushover-freshdesk
	install -m 755 pushover-freshdesk-initscript $(DESTDIR)/etc/init.d/pushover-freshdesk

deploy:
	@if [ -z "$(DEPLOY_TARGET)" ]; then echo "Usage: make DEPLOY_TARGET=sshuser@example.com deploy"; exit 1; fi
	$(MAKE) DESTDIR=_install install
	scp -r _install/* $(DEPLOY_TARGET):/
	@if [ -e "pushover-freshdesk-config-private.php" ]; then \
		scp pushover-freshdesk-config-private.php $(DEPLOY_TARGET):/usr/bin/pushover-freshdesk-config.php; \
	fi
clean:
	rm -rf _install
	rm -f pushover-freshdesk pushover-freshdesk-initscript
