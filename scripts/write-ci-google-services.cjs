const fs = require('node:fs');
const path = require('node:path');

const target = process.argv[2] ?? 'frontend/android/app/google-services.json';

const config = {
  project_info: {
    project_number: '000000000000',
    project_id: 'freebay-ci',
    storage_bucket: 'freebay-ci.appspot.com',
  },
  client: [
    {
      client_info: {
        mobilesdk_app_id: '1:000000000000:android:0000000000000000000000',
        android_client_info: { package_name: 'com.freebay.app' },
      },
      oauth_client: [],
      api_key: [{ current_key: 'ci-placeholder' }],
      services: { appinvite_service: { other_platform_oauth_client: [] } },
    },
  ],
  configuration_version: '1',
};

fs.mkdirSync(path.dirname(target), { recursive: true });
fs.writeFileSync(target, `${JSON.stringify(config, null, 2)}\n`);
console.log(`Wrote CI Firebase config to ${target}`);
