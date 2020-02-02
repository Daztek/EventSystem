# EventSystem
This is an easy to use modular Event System for Neverwinter Nights using NWNX:EE. It consists of a [Core](https://github.com/Daztek/EventSystem/tree/master/Core) system that handles the event dispatching and loading of various [Services](https://github.com/Daztek/EventSystem/tree/master/Services) and [Subsystems](https://github.com/Daztek/EventSystem/tree/master/Subsystems).

*What makes this Event System special?*

As mentioned earlier, it's easy to use and modular. Want to change the Skill needed to identify an item from Lore to Spellcraft? All you have to do after adding the Core system is add the following script file to your module: [es_s_iditem.nss](https://github.com/Daztek/EventSystem/blob/master/Subsystems/es_s_iditem.nss). The next time you run your server it'll automatically load the subsystem and subscribe to the events it needs, all without having to edit any existing scripts.

Want players to get a movement speed increase while traveling on roads and a movement speed decrease while in water? [es_s_travel.nss](https://github.com/Daztek/EventSystem/blob/master/Subsystems/es_s_travel.nss) has you covered!

Lastly, tried a subsystem and it's actually not to your liking? All you have to do is remove its .nss file and it's gone, no fuss.

## Requirements for Core
- **NWNX:EE Plugins**: 
  - Events
  - Object
  - Util
- **NWNX:EE Environment Variables**:
  - `NWNX_CORE_ALLOW_NWNX_FUNCTIONS_IN_EXECUTE_SCRIPT_CHUNK=true`
  - `NWNX_CORE_SHUTDOWN_SCRIPT=es_obj_e_2018`
  - `NWNX_UTIL_PRE_MODULE_START_SCRIPT_CHUNK="#include \"es_inc_core\" void main() { ES_Core_Init(); }"`

## Docker Setup
The only difference on setting up the system in Docker than in native Linux is on setting the `NWNX_UTIL_PRE_MODULE_START_SCRIPT_CHUNK` variable. It should be set up as follows:
  - `NWNX_UTIL_PRE_MODULE_START_SCRIPT_CHUNK=#include "es_inc_core" void main() { ES_Core_Init(); }`

## How To Use
1) Make sure you have enabled the required plugins and set the required environment variables listed above.
2) Add the script files in the [Core](https://github.com/Daztek/EventSystem/tree/master/Core) folder to your module.
3) Add one or more [Services](https://github.com/Daztek/EventSystem/tree/master/Services) and [Subsystems](https://github.com/Daztek/EventSystem/tree/master/Subsystems) script files to your module.
4) Start your server!

## Want to write your own subsystem?
Have a look at heavily commented es_s_example.nss! (TODO)
