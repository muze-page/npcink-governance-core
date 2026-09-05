<?php
/** Validates revision-bound external Docker smoke evidence for Core. */

declare(strict_types=1);

$root         = dirname( __DIR__ );
$toolkit_root = (string) ( getenv( 'NPCINK_ABILITIES_TOOLKIT_PATH' ) ?: dirname( $root ) . '/npcink-abilities-toolkit' );
$path         = (string) ( $argv[1] ?? getenv( 'NPCINK_CORE_WORDPRESS_SMOKE_EVIDENCE' ) ?: '' );

if ( '' === $path || ! is_readable( $path ) ) {
	fwrite( STDERR, "A readable Core M4 WordPress smoke evidence file is required.\n" );
	exit( 2 );
}

$json = file_get_contents( $path );
$data = false !== $json ? json_decode( $json, true ) : null;
if ( ! is_array( $data ) ) {
	fwrite( STDERR, "Core M4 WordPress smoke evidence is not valid JSON.\n" );
	exit( 1 );
}

$git_value = static function ( string $repository, string $command ): string {
	$output = array();
	$status = 0;
	exec( 'git -C ' . escapeshellarg( $repository ) . ' ' . $command . ' 2>/dev/null', $output, $status );
	return 0 === $status ? trim( implode( "\n", $output ) ) : '';
};

$archive_sha256 = static function ( string $repository ): string {
	$output = array();
	$status = 0;
	exec( 'git -C ' . escapeshellarg( $repository ) . ' archive --format=tar HEAD 2>/dev/null | shasum -a 256', $output, $status );
	if ( 0 !== $status || 1 !== preg_match( '/^([0-9a-f]{64})\b/', trim( implode( "\n", $output ) ), $matches ) ) {
		return '';
	}
	return $matches[1];
};

$head                   = $git_value( $root, 'rev-parse HEAD' );
$source_archive_sha256  = $archive_sha256( $root );
$toolkit_head           = $git_value( $toolkit_root, 'rev-parse HEAD' );
$toolkit_archive_sha256 = $archive_sha256( $toolkit_root );
$package_path           = $root . '/build/npcink-governance-core.zip';
$package_sha256         = is_readable( $package_path ) ? hash_file( 'sha256', $package_path ) : false;
$generated_at           = strtotime( (string) ( $data['generated_at'] ?? '' ) );
$now                    = time();

$failures = array();
if ( 'npcink_core_wordpress_smoke_evidence.v1' !== ( $data['schema_version'] ?? null ) ) {
	$failures[] = 'schema_version is unsupported';
}
if ( 'm4-docker' !== ( $data['runner'] ?? null ) ) {
	$failures[] = 'runner must be m4-docker';
}
if ( $head !== ( $data['source_revision'] ?? null ) ) {
	$failures[] = 'source_revision does not match current Core HEAD';
}
if ( '' === $source_archive_sha256 || $source_archive_sha256 !== ( $data['source_archive_sha256'] ?? null ) ) {
	$failures[] = 'source_archive_sha256 does not match current Core HEAD';
}
if ( ! is_string( $package_sha256 ) || $package_sha256 !== ( $data['package_sha256'] ?? null ) ) {
	$failures[] = 'package_sha256 does not match the current Core release ZIP';
}
if ( $toolkit_head !== ( $data['toolkit_revision'] ?? null ) ) {
	$failures[] = 'toolkit_revision does not match the current Toolkit HEAD';
}
if ( '' === $toolkit_archive_sha256 || $toolkit_archive_sha256 !== ( $data['toolkit_archive_sha256'] ?? null ) ) {
	$failures[] = 'toolkit_archive_sha256 does not match the current Toolkit HEAD';
}
if ( '' === trim( (string) ( $data['docker_server_version'] ?? '' ) ) ) {
	$failures[] = 'docker_server_version is missing';
}
if ( false === $generated_at || $generated_at > $now + 300 || $generated_at < $now - 604800 ) {
	$failures[] = 'generated_at must be within the last seven days';
}

$required_profiles = array(
	'wordpress-6.9.4-php-8.0' => array( 'wordpress' => '6.9.4', 'php' => '8.0' ),
	'wordpress-7.0-php-8.5'  => array( 'wordpress' => '7.0', 'php' => '8.5' ),
);
$profiles = is_array( $data['profiles'] ?? null ) ? $data['profiles'] : array();
foreach ( $required_profiles as $profile_id => $expected ) {
	$profile = is_array( $profiles[ $profile_id ] ?? null ) ? $profiles[ $profile_id ] : array();
	if ( 'passed' !== ( $profile['status'] ?? null )
		|| true !== ( $profile['installed_from_zip'] ?? null )
		|| $expected['wordpress'] !== ( $profile['wordpress'] ?? null )
		|| $expected['php'] !== ( $profile['php'] ?? null )
		|| (int) ( $profile['assertions'] ?? 0 ) < 1
	) {
		$failures[] = 'required profile failed validation: ' . $profile_id;
	}
}

if ( array() !== $failures ) {
	foreach ( $failures as $failure ) {
		fwrite( STDERR, 'Core M4 evidence rejected: ' . $failure . "\n" );
	}
	exit( 1 );
}

printf(
	"Revision-bound Core M4 WordPress smoke evidence: ok (%s, package %s, Docker %s)\n",
	$head,
	(string) $package_sha256,
	(string) $data['docker_server_version']
);
