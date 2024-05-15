import os
import traceback
from time import sleep

from selenium.webdriver.common.by import By

from common.bash_utils import execute_bash_commands
from common.web_utils import get_browser

# Get browser
browser = get_browser()


def get_direct_download_link() -> str:
    # Get correct url and open the page
    url = f"https://files.minecraftforge.net/maven/net/minecraftforge/forge/index_{os.environ['MINECRAFT_VERSION']}.html"
    if str(os.environ['MINECRAFT_VERSION']) == "latest":
        url = "http://files.minecraftforge.net/"

    print(f"Opening url: {url}")
    browser.get(url)
    sleep(5)

    # Find download box for latest release of Forge
    download_box_latest = browser.find_element(By.TAG_NAME, "body") \
        .find_element(By.XPATH, "//div[contains(@class, 'downloads')]") \
        .find_element(By.XPATH, "//div[contains(@class, 'download')]") \
        .find_element(By.XPATH, "//div[contains(@class, 'title')]")

    if "download latest" in str(download_box_latest.text).lower():
        # Find the box containing installer download and extract the direct link (without ads)
        installer_box_xpath = ".." \
                              "//div[contains(@class, 'links')]" \
                              "//div[contains(@class, 'link')]" \
                              "//a" \
                              "//span[contains(text(), 'Installer')]"
        installer_box_element = download_box_latest.find_element(By.XPATH, installer_box_xpath)
        installer_download_url = installer_box_element.find_element(By.XPATH, "..").get_attribute("href")

        return "https://" + str(installer_download_url).split("https://", 2)[2]


# MAIN CODE #
try:
    # Get direct download link
    direct_download_link = get_direct_download_link()
    print(f"Link scraped is {direct_download_link}")

    # Execute bash scripts to download and place the jar in a correct place
    path = "/McMyAdmin/Minecraft"
    file_path_to_backup = f"{path}/minecraft_server.jar"
    installer_file_path = f"{path}/forge-installer.jar"

    commands = [
        ["mv", file_path_to_backup, f"{file_path_to_backup}_backup"],
        ["wget", "-O", installer_file_path, direct_download_link],
    ]
    execute_bash_commands(commands)
except Exception as e:
    # PEP 8: E722 do not use bare 'except'
    # I am such a bad boy for not following the rules
    print("***** An error occurred!")
    traceback.print_exc()
finally:
    # Close browser
    browser.quit()
