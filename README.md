# Tadpoles App Image Downloader

This is a command line script to download images and videos of your child in batches from the [Tadpoles](https://www.tadpoles.com/parents) parent web page.

This script is intended to help streamline the bulk download of your child's photos, it will only give you access to images you already have access to via Tadpoles.

## Getting started

### Dependencies

Uses [jq](https://stedolan.github.io/jq/) for bash to process json responses from the API. If you have [homebrew](https://docs.brew.sh/Installation) installed, you can run `brew install jq` to install.

**Note**: I have used this script primarily on a Mac. It may be possible to [run this script on Windows 10 using the Windows Subsystem for Linux](https://www.thewindowsclub.com/how-to-run-sh-or-shell-script-file-in-windows-10/), but I have not tested it personally. Instructions below mostly assume you're using a Mac.

### Authentication

This script does not attempt to authenticate you to the [Tadpoles](https://www.tadpoles.com/parents) website, you must login to the website and copy a cookie value to authenticate. You will need to manually create two files, `.cookie` and `.email`, and follow the steps below to provide your login information.

1. Using Chrome, log into the [Tadpoles](https://www.tadpoles.com/parents) site, and open the Developer console to the Network panel
2. Find the call that starts with "events?..." and select "Copy as curl"
3. Paste the curl command in your text editor to view
4. Paste the value of the `-H 'Cookie: '` param into a `.cookie` file in the same folder as `./download_tadpoles.sh`
5. Paste the value of the `-H 'x-tadpoles-uid: '` param into a `.email` file in the same folder as `./download_tadpoles.sh`

You will need to repeat the cookie step each time you use the script, as your login on the Tadpoles page will expire.

### Download Location (Optional)

If you would like to download the images to a particular folder, create a `.download_location` file and enter the absolute path to the folder. The script will automatically create folder for each month. The default location will be in the same folder as the script.

### Running the script

Open Terminal and navigate to the folder where you have downloaded the script.  To run, type `./download_tadpoles.sh` and follow the instructions to enter a start and end date.  It is recommended to download 30-60 days at a time as there is an upper limit of 215 images per batch.  The script will default to a time period of 30 days if you enter a start date and use the default end date.

It is safe to rerun the script over a time period, it will skip images that have already been downloaded.

### Troubleshooting Tips

1) If the script will not run with an error of "-bash: ./download_tadpoles.sh: Permission denied", type `chmod +x download_tadpoles.sh` to enable execute on the script.

2) If you get the "Found 0 for date range" when you see images in the browser view, your `.cookie` file might have errors.  Make sure you have removed the word "Cookie:" and the single quotes around the cookie field, but kept the ending double quote.

3) The `.email` file should match the email used for login without anything else.
