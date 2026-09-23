# mkl_cleanup

Automatic vehicle cleanup for FiveM. Every few minutes it warns the server and removes the vehicles nobody is using, while leaving alone the ones that are still in play.

Made for MKL PVP and released for free.

## Features

- Cleanup every X minutes with warnings at 60, 30 and 10 seconds (configurable)
- Smart protection, a vehicle is kept if:
  - someone is inside it
  - someone was inside it in the last few minutes
  - it was just spawned
  - a player is close to it
  - its owner is online and close to it
  - an admin protected it
- Routing bucket aware: a player in another dimension does not keep your car alive
- Works with Qbox, QBCore, ESX or standalone (framework is detected automatically)
- Chat and ox_lib notifications (ox_lib is optional)
- English and Spanish included, easy to add more
- Admin commands with ACE permissions
- Exports and events so other resources can protect vehicles or react before one is deleted
- Server side only, no client script, no loops on players' machines

## Installation

1. Download the latest release and put the `mkl_cleanup` folder in your `resources`.
2. Add it to your `server.cfg`:

```cfg
ensure mkl_cleanup
```

3. Give your admins access to the commands (skip this if your admin group already has `command allow`):

```cfg
add_ace group.admin command.cleanvehicles allow
add_ace group.admin command.protectvehicle allow
add_ace group.admin command.cleanupinfo allow
```

## Configuration

Everything is in `config.lua`.

| Option | Default | Description |
| --- | --- | --- |
| `Locale` | `'en'` | `'en'` or `'es'` |
| `IntervalMinutes` | `5` | Minutes between cleanups |
| `Warnings` | `{ 60, 30, 10 }` | Seconds before the cleanup when players are warned |
| `RecentUseSeconds` | `180` | Keep vehicles someone was inside in the last X seconds |
| `GraceSeconds` | `120` | Keep vehicles spawned in the last X seconds |
| `NearbyPlayerDistance` | `30.0` | Keep vehicles with a player this close (`0` disables it) |
| `OwnerDistance` | `100.0` | Keep vehicles whose owner is this close (`0` disables it) |
| `OwnerStateKeys` | `{ 'ownercid', 'owner', 'citizenid' }` | State bag keys used to find the owner of a vehicle |
| `IgnoreModels` | `{}` | Models that are never removed, e.g. `'police'` |
| `Notify.chat` | `true` | Send warnings to the chat |
| `Notify.oxlib` | `true` | Send warnings as ox_lib notifications (only if ox_lib is running) |
| `Commands` | see file | Command names |
| `TrackSeconds` | `10` | How often vehicle usage is sampled |

### Vehicle owners

To know who owns a vehicle the script reads its state bag. If your garage script sets any of the keys in `OwnerStateKeys` to the owner's citizenid (Qbox/QBCore), identifier (ESX) or license, the owner rule works out of the box. If it doesn't, add one line where your garage spawns the vehicle:

```lua
Entity(vehicle).state:set('owner', citizenid, false)
```

## Commands

| Command | Description |
| --- | --- |
| `/cleanvehicles [seconds]` | Brings the next cleanup forward (default 30 seconds, players get warned) |
| `/protectvehicle` | Protects or unprotects the vehicle you are in |
| `/cleanupinfo` | Time until the next cleanup and result of the last one |

`/cleanvehicles` and `/cleanupinfo` also work from the server console.

## Exports

```lua
-- Never remove this vehicle
exports.mkl_cleanup:SetProtected(vehicle, true)

-- Check if a vehicle is protected
local protected = exports.mkl_cleanup:IsProtected(vehicle)

-- Run a cleanup in X seconds (0 = right now)
exports.mkl_cleanup:ForceCleanup(30)

-- Unix time of the next cleanup
local nextAt = exports.mkl_cleanup:GetNextCleanup()
```

## Events

Both events are server side.

`mkl_cleanup:beforeDelete` fires right before a vehicle is deleted, while it still exists, so you can save it to your database, send it to an impound, etc.

```lua
AddEventHandler('mkl_cleanup:beforeDelete', function(vehicle, info)
    -- info.model, info.plate, info.owner, info.bucket
    MySQL.update('UPDATE player_vehicles SET state = 2 WHERE plate = ?', { info.plate })
end)
```

`mkl_cleanup:finished` fires after every cleanup with a summary.

```lua
AddEventHandler('mkl_cleanup:finished', function(report)
    -- report.removed, report.kept, report.reasons (table: reason -> count)
    print(('Cleanup removed %s vehicles'):format(report.removed))
end)
```

## Adding a language

Open `locales.lua`, copy the `en` block, translate it and set `Config.Locale` to its key.

## Español

Limpieza automatica de vehiculos. Cada X minutos avisa a todo el servidor y borra los vehiculos que nadie usa, respetando los que estan en uso, recien sacados, con jugadores cerca o con su dueño cerca. Pon `Config.Locale = 'es'` para tener los textos en español; los nombres de los comandos se cambian en `Config.Commands`.

## License

[MIT](LICENSE)
