<?php

require_once( dirname( __DIR__ ) . '/vendor/autoload.php' );

$root_dir = dirname( __DIR__ );
$dotenv = new Dotenv\Dotenv( $root_dir );

if ( file_exists( $root_dir . '/.env' ) ) {
	$dotenv->load();
	$dotenv->required( ['DB_NAME', 'DB_USER', 'DB_PASSWORD', 'DB_HOST'] );
}

$db_user = getenv( 'DB_USER' );
$db_password = getenv( 'DB_PASSWORD' );
$db_host = getenv( 'DB_HOST' );
$db_name = getenv( 'DB_NAME' );

$backup_path = $root_dir . '/db/';
$backup_name = $backup_path . $db_name . '_' . date( 'Y-m-d-His' ) . '.sql.bz2';

$shared_backup_path = $root_dir . '/../../shared/db/backup';

exec( "/usr/local/bin/mysqldump --user=$db_user --password=$db_password --host=$db_host $db_name --lock-tables=false | bzip2 -9 > $backup_name" );
exec( "cp $backup_name $shared_backup_path" );

exec( "cd $backup_path && (ls -t|head -n 10;ls)|sort|uniq -u|xargs rm" );
exec( "cd $shared_backup_path && (ls -t|head -n 10;ls)|sort|uniq -u|xargs rm" );