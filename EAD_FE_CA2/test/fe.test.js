const assert = require('assert');

describe('Frontend Smoke Test', function () {
  it('should load config and confirm app name', function () {
    const config = require('../config/config.json');
    assert.strictEqual(config.development.app_name, 'Recipe Tracker');
  });

  it('should confirm exposed port is set', function () {
    const config = require('../config/config.json');
    assert.ok(config.development.exposedPort);
  });
});
