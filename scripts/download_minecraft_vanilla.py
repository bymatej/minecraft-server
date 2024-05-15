import os
import traceback
from time import sleep

from selenium.webdriver.common.by import By

from common.bash_utils import execute_bash_commands
from common.web_utils import get_browser

# Get browser
browser = get_browser()


def get_latest_download_link() -> str:
    # Get correct url and open the page
    url = "https://mcversions.net/"
    browser.get(url)
    sleep(5)

    latest_release_p_element_xpath = "//span[text()='Latest Release']/parent::div/p[1]"
    latest_release_p_element = browser.find_element(By.XPATH, latest_release_p_element_xpath)
    latest_version = latest_release_p_element.text.split("\n")[0].replace("✨", "")
    return f"https://mcversions.net/download/{latest_version}"


def get_version_download_link() -> str:
    return f"https://mcversions.net/download/{os.environ['MINECRAFT_VERSION']}"


def get_direct_download_link() -> str:
    # Get download page
    if str(os.environ['MINECRAFT_VERSION']) == "latest":
        download_link = get_latest_download_link()
    else:
        download_link = get_version_download_link()

    # Find download box for latest release of Forge
    print(f"Opening url: {download_link}")
    browser.get(download_link)
    sleep(5)

    for a in browser.find_elements(By.TAG_NAME, "a"):
        if str(a.get_attribute("download")).startswith("minecraft_server-"):
            return str(a.get_attribute("href"))


# MAIN CODE #
try:
    # Get direct download link
    direct_download_link = get_direct_download_link()
    print(f"Link scraped is {direct_download_link}")

    # Execute bash scripts to download and place the jar in a correct place
    file_path = "/McMyAdmin/Minecraft/minecraft_server.jar"
    commands = [
        ["mv", file_path, f"{file_path}_backup"],
        ["wget", "-O", file_path, direct_download_link]
    ]
    execute_bash_commands(commands)
except Exception as e:
    # PEP 8: E722 do not use bare 'except'
    # I am such a hooligan for not following the rules
    print("***** An error occurred!")
    traceback.print_exc()
finally:
    # Close browser
    browser.quit()
