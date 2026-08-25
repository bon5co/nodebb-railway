'use strict';

// Writes NodeBB's config.json from the environment with a real JSON encoder.
//
// The category leader builds this file inside a start command
// (`sh -c "... echo $CONFIG_JSON > setup.json ..."`). The value is expanded by
// the outer shell and then re-parsed by the inner one, which strips the quotes,
// so NodeBB receives `{database: postgres, ...}` and aborts. Encoding the object
// here removes the shell from the path entirely.

const fs = require('fs');

function required(name) {
	const value = process.env[name];
	if (!value) {
		console.error(`[railway] ${name} is required but empty.`);
		process.exit(1);
	}
	return value;
}

const port = process.env.PORT || '4567';
const config = {
	url: required('NODEBB_URL'),
	secret: required('NODEBB_SECRET'),
	database: 'postgres',
	// Railway terminates TLS and replaces inbound X-Forwarded-For, and Express
	// takes the left-most address, so the forum logs and rate-limits the real
	// client instead of the edge.
	trust_proxy: true,
	port: Number(port),
	postgres: {
		host: required('NODEBB_DB_HOST'),
		port: process.env.NODEBB_DB_PORT || '5432',
		username: required('NODEBB_DB_USER'),
		password: required('NODEBB_DB_PASSWORD'),
		database: required('NODEBB_DB_NAME'),
		ssl: String(process.env.NODEBB_DB_SSL || 'false') === 'true',
	},
};

const target = process.argv[2];
fs.writeFileSync(target, `${JSON.stringify(config, null, 4)}\n`);
console.log(`[railway] wrote ${target} (port ${config.port}, db ${config.postgres.host})`);
