from common.bash_utils import apply_configuration_to_file
from common.configuration_enums import EnvironmentToMinecraftPropertiesMapping

apply_configuration_to_file("/McMyAdmin/Minecraft/server.properties", EnvironmentToMinecraftPropertiesMapping)
