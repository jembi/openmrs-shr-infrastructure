OpenSHR Ubuntu Packaging
========================

Ubuntu packaging scripts. Currently supports:
* 14.04 Trusty

Packaging Process
=================
It's recommended to run the packaging script within the OpenSHR Vagrant environment. Vagrant will ensure that all the correct helper packages are installed and importantly ensure that the required artifacts are available in the `../artifacts/` directory. If you wish to run the script outside of Vagrant, first ensure that all the latest artifacts are available.

The following is the process to follow for packaging and releasing a new OpenSHR build:
* Make sure you're up to date: `git pull`
* Clear out the `../artifacts` directory
* `cd ..`
* `vagrant up`
* `vagrant ssh`
* Edit `targets/{target}/debian/control` and change *Maintainer* to yourself. This step isn't necessary, but it's good to keep an accurate log of the person doing the release.
* If uploading to Launchpad, you should create or import a GPG key for signing the package:
  * https://help.launchpad.net/YourAccount/ImportingYourPGPKey
  * If using an existing key, import it into your Vagrant instance
* Run the packaging script:
  * `cd /vagrant/packaging`
  * `./create-deb.sh`

When running the script, you will be asked whether you want to upload the build(s) to Launchpad. The OpenHIE PPA (https://launchpad.net/~openhie) should be used for all official releases.

After completing, the build number will be bumped and the build logged to `target/{target}/debian/changelog`. Commit the updated changelog(s) to GitHub on the master branch.

The new packages will be available in the `packaging/builds` directory.

Troubleshooting
---------------
 * If you get signing errors try symlink your ~/.gnupg/ folder to packaging working directory `ln -s ~/.gnupg/`
 * If your upload to launchpad gets stuck on the last byte :crying_cat_face: then try reset your router and put your machine in the DMZ (weird I know, apparently some router bug with large ftp). Otherwise try this: https://answers.launchpad.net/launchpad/+faq/1738

Java 8 PPA
==========
The package depends on Java 8 provided by the webupd8 team PPA `ppa:webupd8team/java`
