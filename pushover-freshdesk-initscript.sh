#!/usr/bin/env bash
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

. /lib/lsb/init-functions

NAME=pushover-freshdesk
EXECNAME=/usr/bin/${NAME}
PIDFILE=/var/run/${NAME}.pid
LOGFILE=/var/log/${NAME}.log

case "$1" in
	start)
		echo -n "Starting ${NAME}: "
		start-stop-daemon -S -b -m -p ${PIDFILE} --startas /bin/bash -- -c "exec ${EXECNAME} >>${LOGFILE} 2>&1"
		$0 status
		;;
	stop)
		echo -n "Stopping ${NAME}: "
		start-stop-daemon -K -p ${PIDFILE}
		rm -f ${PIDFILE}
		echo "OK."
		;;
	restart)
		$0 stop
		$0 start
		;;
	status)
		if start-stop-daemon -T -p ${PIDFILE}; then
			echo "running with pid $(head -n1 ${PIDFILE})."
		else
			echo "not running."
		fi
		;;
	*)
		echo "Usage: $0 [start|stop|restart|status]"
		;;
esac
