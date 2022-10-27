import os

import requests
from requests.exceptions import HTTPError

from common.bash_utils import execute_bash_commands


def get_latest_build(json: dict) -> dict:
    all_builds: list = json['builds']
    all_builds.reverse()
    return all_builds[0]


def get_direct_download_link() -> str:
    if str(os.environ['MINECRAFT_VERSION']) == "latest":
        url = "xxx"

    version: str = os.environ['MINECRAFT_VERSION']
    url: str = 'https://api.papermc.io/v2/projects/paper/versions/' + version + '/builds/'
    try:
        response = requests.get(url)
        response.raise_for_status()
        build_id: str = get_latest_build(response.json())['build']
        jar_name: str = get_latest_build(response.json())['downloads']['application']['name']

        return f'{url}{build_id}/downloads/{jar_name}'

    except HTTPError as http_err:
        print(f'HTTP error occurred: {http_err}')
    except Exception as err:
        print(f'Other error occurred: {err}')


# MAIN CODE #
try:
    # Get direct download link
    direct_download_link = get_direct_download_link()
    print(f"Link obtained from JSON response is {direct_download_link}")

    # Execute bash scripts to download and place the jar in a correct place
    file_path = "/McMyAdmin/Minecraft/minecraft_server.jar"
    commands = [
        ["mv", file_path, f"{file_path}_backup"],
        ["wget", "-O", file_path, direct_download_link]
    ]
    execute_bash_commands(commands)
except Exception as e:
    # PEP 8: E722 do not use bare 'except'
    # I am such a bad boy for not following the rules
    print(f"***** An error occurred! \n{e}")
