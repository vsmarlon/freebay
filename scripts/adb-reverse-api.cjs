const { execFileSync } = require('node:child_process');

function connectedDevices(output) {
  return output.split(/\r?\n/).slice(1)
    .map((line) => line.trim().split(/\s+/))
    .filter(([id]) => id)
    .map(([id, state]) => ({ id, state }));
}

function selectDevice(output, selected) {
  const rows = connectedDevices(output);
  const devices = rows.filter(({ state }) => state === 'device').map(({ id }) => id);
  if (selected) {
    if (!/^[A-Za-z0-9._:-]+$/.test(selected)) throw new Error('Selected adb device has invalid characters.');
    if (!devices.includes(selected)) throw new Error(`Selected adb device is unavailable or unauthorized: ${selected}`);
    return selected;
  }
  if (devices.length === 0) throw new Error('No authorized adb device. Connect and authorize a device, or use --transport lan.');
  if (devices.length > 1) throw new Error(`Multiple adb devices (${devices.join(', ')}). Select one with --device or FREEBAY_ADB_DEVICE.`);
  return devices[0];
}

function configureReverse({ adb = process.env.ADB || 'adb', selected = process.env.FREEBAY_ADB_DEVICE, execFile = execFileSync } = {}) {
  let devicesOutput;
  try {
    devicesOutput = execFile(adb, ['devices'], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
  } catch {
    throw new Error('adb is unavailable or could not list devices. Install/configure Android platform-tools.');
  }
  const device = selectDevice(devicesOutput, selected);
  try {
    execFile(adb, ['-s', device, 'reverse', 'tcp:3000', 'tcp:3000'], { stdio: 'ignore' });
  } catch {
    throw new Error(`adb reverse failed for selected device ${device}; USB launch was not started.`);
  }
  return device;
}

if (require.main === module) {
  try {
    const device = configureReverse();
    console.log(`[FreeBay] adb reverse ready for selected device ${device}.`);
  } catch (error) {
    console.error(`[FreeBay] ${error.message}`);
    process.exitCode = 1;
  }
}

module.exports = { configureReverse, connectedDevices, selectDevice };
