OpenSHR Ubuntu Packaging
========================

Ubuntu packaging scripts.

Packaging Process
=================
It's recommended to run the packaging script within the OpenSHR Vagrant environment. Vagrant will ensure that all the correct helper packages are installed and importantly ensure that the required artifacts are available in the `../artifacts/` directory. If you wish to run the script outside of Vagrant, first ensure that all the latest artifacts are available.

The following is the process to follow for packaging and releasing a new OpenSHR build:
* Make sure you're up to date: `git pull`
* Clear out the `../artifacts` directory
* `cd ..`
* `vagrant up`
* `vagrant ssh`
* `> cd /vagrant/packaging`
* Edit `targets/{target}/debian/control` and change *Maintainer* to yourself. This step isn't nescessary, but it's good to keep an accurate log of the person doing the release.
* Run the packaging script: `./create-deb.sh`

When running the script, you will be asked whether you want to upload the build(s) to LaunchPad. The OpenHIE PPA (https://launchpad.net/~openhie) should be used for all official releases.

After completing, the build number will be bumped and the build logged to `target/{target}/debian/changelog`. Commit the updated changelog(s) to GitHub on the master branch.

The new packages will be available in the `packaging/builds` directory.

Java 8 PPA
==========
The package depends on Java 8 provided by the webupd8 team: http://www.webupd8.org/2012/09/install-oracle-java-8-in-ubuntu-via-ppa.html
