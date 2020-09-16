# EventSystem
This is an easy to use modular Event System for Neverwinter Nights using NWNX:EE. TODO: Write a better description.

## Requirements for Core
- **NWNX:EE Plugins**: 
  - Object
  - Util
- **NWNX:EE Environment Variables**:
  - `NWNX_CORE_ALLOW_NWNX_FUNCTIONS_IN_EXECUTE_SCRIPT_CHUNK=true`
  - `NWNX_CORE_SHUTDOWN_SCRIPT=es_obj_e_3019`
  - `NWNX_UTIL_PRE_MODULE_START_SCRIPT_CHUNK="#include \"es_inc_core\" void main() { ES_Core_Init(); }"`

## Docker Setup
The only difference on setting up the system in Docker than in native Linux is on setting the `NWNX_UTIL_PRE_MODULE_START_SCRIPT_CHUNK` variable. It should be set up as follows:
  - `NWNX_UTIL_PRE_MODULE_START_SCRIPT_CHUNK=#include "es_inc_core" void main() { ES_Core_Init(); }`

## How To Use
1) Make sure you have enabled the required plugins and set the required environment variables listed above.
2) Add the script files in the [Core](https://github.com/Daztek/EventSystem/tree/master/Core) folder to your module.
3) Add one or more [Core Components](https://github.com/Daztek/EventSystem/tree/master/Components/Core), [Services](https://github.com/Daztek/EventSystem/tree/master/Components/Services) and [Subsystems](https://github.com/Daztek/EventSystem/tree/master/Components/Subsystems) script files to your module.
4) Start your server!

## Want to write your own subsystem?
Have a look at heavily commented es_s_example.nss! (TODO)
