<?php
/**
 * Npcink Governance Core uninstall policy.
 *
 * Governance records are intentionally preserved on uninstall. Sites may
 * require proposal and audit history for retention, incident, or compliance
 * purposes; deletion must be an explicit, separately reviewed operation.
 *
 * @package NpcinkGovernanceCore
 */

if ( ! defined( 'WP_UNINSTALL_PLUGIN' ) ) {
	exit;
}

// Intentionally no-op: proposals, audit events, app metadata, and read
// authorization records are retained unless a future explicit purge contract
// is added.
