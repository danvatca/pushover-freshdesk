#!/usr/bin/php -q
<?php
/**
 * Copyright (C) 2014, Dan Vatca <dan.vatca@gmail.com>
 * All rights reserved.
 *  Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

include_once(__DIR__ . '/pushover-freshdesk-config.php');

function getFreshDeskTicketsPage($url, $userPassword = '') {
	$curlHandle = curl_init();
	$timeout = 5;
	curl_setopt($curlHandle, CURLOPT_URL, $url);
	curl_setopt($curlHandle, CURLOPT_RETURNTRANSFER, 1);
	curl_setopt($curlHandle, CURLOPT_TIMEOUT, $timeout);
	curl_setopt($curlHandle, CURLOPT_USERPWD, $userPassword);
	$rawTickets = curl_exec($curlHandle);
	curl_close($curlHandle);
	return json_decode($rawTickets);
}

function getAllFreshDeskOpenedTickets() {
	global $FRESHDESK_URL;
	global $FRESHDESK_USER;
	global $FRESHDESK_PASS;

	$no = 0;
	$page = 0;
	$tickets = [];
	do {
		$page++;
		$currentPageOfTickets = getFreshDeskTicketsPage(
			"http://$FRESHDESK_URL/helpdesk/tickets/filter/open?format=json&page=$page",
			"$FRESHDESK_USER:$FRESHDESK_PASS"
		);
		array_walk($currentPageOfTickets, function ($ticket) use (&$tickets) { $tickets[] = $ticket; });
		$numTickets = count($currentPageOfTickets);
		$no += $numTickets;
	} while ($numTickets > 0);
	return $tickets;
}

function compare_by_updated_at($a, $b) {
	return strcmp($a->updated_at, $b->updated_at);
}

function compare_by_display_id($a, $b) {
	return strcmp($a->display_id, $b->display_id);
}

function sendNotification($title, $message, $message_url = '') {
	global $PUSHOVER_API_KEY;
	global $PUSHOVER_USER_KEY;
	$url = 'https://api.pushover.net/1/messages.json';

	$curlHandle = curl_init();
	$timeout = 5;
	$priority = 1;
	curl_setopt($curlHandle, CURLOPT_URL, $url);
	curl_setopt($curlHandle, CURLOPT_RETURNTRANSFER, 1);
	curl_setopt($curlHandle, CURLOPT_TIMEOUT, $timeout);
	curl_setopt($curlHandle, CURLOPT_POST, 1);
	curl_setopt($curlHandle, CURLOPT_POSTFIELDS, http_build_query(array(
		'token' => $PUSHOVER_API_KEY,
		'user' => $PUSHOVER_USER_KEY,
		'message' => $message,
		'title' => $title,
		'priority' => $priority,
		'url' => $message_url
	)));

	$jsonResponse = curl_exec($curlHandle);
	curl_close($curlHandle);

	$response = json_decode($jsonResponse);
	if ($response->status != 1) {
		fprintf(STDERR, "ERROR: Failed to send notification. Details follow: ");
		var_dump($response);
	}
}

function main_loop() {
	global $FRESHDESK_URL;
	do {
		$currentTickets = getAllFreshDeskOpenedTickets();
		if (isset($currentTickets) && isset($beforeTickets)) {
			$added = array_udiff($currentTickets, $beforeTickets, 'compare_by_display_id');
			$removed = array_udiff($beforeTickets, $currentTickets, 'compare_by_display_id');
			$modified = array_udiff(
				array_uintersect($currentTickets, $beforeTickets, 'compare_by_display_id'),
				array_uintersect($beforeTickets, $currentTickets, 'compare_by_display_id'),
				'compare_by_updated_at');

			foreach ($added as $ticket) {
				sendNotification('New', $ticket->subject,
					sprintf("http://%s/helpdesk/tickets/%d",$FRESHDESK_URL, $ticket->display_id)
				);
				printf("[%s] New: %s\n", $ticket->updated_at, $ticket->subject);
			}

			foreach ($removed as $ticket) {
				sendNotification('Gone', $ticket->subject);
				printf("[%s] Gone: %s\n", $ticket->updated_at, $ticket->subject);
			}

			foreach ($modified as $ticket) {
				sendNotification('Updated', $ticket->subject,
					sprintf("http://%s/helpdesk/tickets/%d",$FRESHDESK_URL, $ticket->display_id)
				);
				printf("[%s] Updated: %s\n", $ticket->updated_at, $ticket->subject);
			}
		}

		$beforeTickets = $currentTickets;
		sleep(60); // We are rate limited by Freshdesk to 1000 requests per hour. Do not go below 5 seconds.
	} while (true);
}

main_loop();
