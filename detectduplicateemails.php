<?php
/**
 * 4PSA VoipNow - Script that detects if an email address is associated with
 * more then one user address any user; users are selected from sql.voipnow.client
 * The script generates a csv file with the information about the accounts with
 * duplicate emails (Customer ID, Name, Level, Company, Username, Email)
 *
 * To run the script you should use the next command:
 *
 *  $PHP_BIN --define register_argc_argv=On  --define open_basedir=${OPEN_BASEDIR} --define include_path=${INCLUDE_DIR}  -q ${SCRIPT_DIR}/detectduplicateemails.php
 *
 * where:
 *       PHP_BIN = /usr/local/httpsa/php/bin/php
 *      {OPEN_BASEDIR} = /usr/local/voipnow:/sbin:/tmp:/etc/voipnow:/etc/asterisk:/usr/local/hubphp:/usr/share/GeoIP
 *      {INCLUDE_DIR} = /usr/local/voipnow/admin/htdocs:/usr/local/hubphp/libs/PEAR:/usr/local/hubphp:/usr/local/hubphp/libs
 *      {SCRIPT_DIR} = /usr/local/voipnow/admin/htdocs
 *
 *
 * Copyright (c) 2005-2015 Rack-Soft, Inc. All rights reserved.
 */
use VN\Boot\Loader;
use HS\GeneralException;
use HS\Product\Product;

/**
 * Name of the CSV
 */

$DATE = date('Ymdhis', time());
$FILENAME = 'duplicate_emails' . $DATE . '.csv';
$FILENAME_FULL_PATH = '/tmp/' . $FILENAME;

ob_start();

/* include autoloader functions */
require_once('plib/func.php');
require_once('plib/autoload.php');

/* Set the family and subsystem from where to load the directives */
$familySubsystem[Loader::FAMILY_VN] = Loader::SUBSYS_VN_UPGRADE;
$bootEnv = Loader::start($familySubsystem);
$product = Product::getInstance($bootEnv);
$debugOn = $product->queryEnv('VOIPNOW_DEBUG');

/**
 * @param $text
 */
function writeToLog($text) {
    global $debugOn;
    if($debugOn) {
        error_log($text);
    }
}

/* Fetch the SQL database connection */
try {
    $mysql = $product->getComplexStorage(Product::STORAGE_COMPLEX_MYSQL);
} catch (GeneralException $e) {
    writeToLog("\nMySQL root credentials could not be located, upgrade schema is not executed!\n");
    exit(90);
}

$sqlStatement = 'SELECT client.id, TRIM(name) as name, level, company, username,  email
                 FROM client, hs_account
                 WHERE client.id = hs_account.userID AND email IN
                  (SELECT email FROM
                    (SELECT email, COUNT(id) AS no_of_emails
                      FROM client
                      GROUP BY email
                    ) AS email_table
                  WHERE no_of_emails !=1 AND email IS NOT NULL
                  )';

$rows = $mysql->sqlQueryFetchall($sqlStatement);
if(empty($rows)) {
    /* Nothing to do */
    echo "No duplicate emails found\n";
    exit(0);
}

/**
 * If file exists remove it and create a new one
 */

if(file_exists($FILENAME_FULL_PATH)) {
    unlink($FILENAME_FULL_PATH);
}

if(!$csvFile = fopen($FILENAME_FULL_PATH, 'w')) {
    echo "Cannot open file ".$FILENAME_FULL_PATH . "\n";
    exit(1);
}
header( 'Content-Type: text/csv' );
header( 'Content-Disposition: attachment;filename=' . $FILENAME);

fputcsv($csvFile, array('Customer ID', 'Name', 'Level', 'Company', 'Username', 'Email'));
$count_emails  = 0;
foreach ($rows as $row) {
    fputcsv($csvFile, $row);
    $count_emails ++;
}

if(!fclose($csvFile)) {
    echo "Cannot close file ". $FILENAME_FULL_PATH;
    exit(2);
}

echo "Found $count_emails duplicate emails. A csv file with complete information was saved at " . $FILENAME_FULL_PATH . "\n";
exit(0);

