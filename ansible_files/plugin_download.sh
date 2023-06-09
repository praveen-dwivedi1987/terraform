Skip to content
 
Search…
All gists
Back to GitHub
@praveen-dwivedi1987 
@micw
micw/install_jenkins_plugin.sh
Last active 3 months ago • Report abuse
145
86
Code
Revisions
3
Stars
144
Forks
86
<script src="https://gist.github.com/micw/e80d739c6099078ce0f3.js"></script>
Script to install one or more jenkins plugins including dependencies while jenkins is offline
install_jenkins_plugin.sh
#!/bin/bash

set -e

if [ $# -eq 0 ]; then
  echo "USAGE: $0 plugin1 plugin2 ..."
  exit 1
fi

plugin_dir=/var/lib/jenkins/plugins
file_owner=jenkins.jenkins

mkdir -p /var/lib/jenkins/plugins

installPlugin() {
  if [ -f ${plugin_dir}/${1}.hpi -o -f ${plugin_dir}/${1}.jpi ]; then
    if [ "$2" == "1" ]; then
      return 1
    fi
    echo "Skipped: $1 (already installed)"
    return 0
  else
    echo "Installing: $1"
    curl -L --silent --output ${plugin_dir}/${1}.hpi  https://updates.jenkins-ci.org/latest/${1}.hpi
    return 0
  fi
}

for plugin in $*
do
    installPlugin "$plugin"
done

changed=1
maxloops=100

while [ "$changed"  == "1" ]; do
  echo "Check for missing dependecies ..."
  if  [ $maxloops -lt 1 ] ; then
    echo "Max loop count reached - probably a bug in this script: $0"
    exit 1
  fi
  ((maxloops--))
  changed=0
  for f in ${plugin_dir}/*.hpi ; do
    # without optionals
    #deps=$( unzip -p ${f} META-INF/MANIFEST.MF | tr -d '\r' | sed -e ':a;N;$!ba;s/\n //g' | grep -e "^Plugin-Dependencies: " | awk '{ print $2 }' | tr ',' '\n' | grep -v "resolution:=optional" | awk -F ':' '{ print $1 }' | tr '\n' ' ' )
    # with optionals
    deps=$( unzip -p ${f} META-INF/MANIFEST.MF | tr -d '\r' | sed -e ':a;N;$!ba;s/\n //g' | grep -e "^Plugin-Dependencies: " | awk '{ print $2 }' | tr ',' '\n' | awk -F ':' '{ print $1 }' | tr '\n' ' ' )
    for plugin in $deps; do
      installPlugin "$plugin" 1 && changed=1
    done
  done
done

echo "fixing permissions"

chown ${file_owner} ${plugin_dir} -R

echo "all done"
Load earlier comments...
@chuxau
chuxau commented on Apr 11, 2015
Hi, just a note to say thanks for the script. I cloned and modified it to expect a list of plugins, to download only specific versions of plugins, and to auto-install only non-optional dependencies. I also removed the static reference to jenkins plugins directory.

@vkuusk
vkuusk commented on Mar 17, 2016
Thank you, micw !

@johncloutier
johncloutier commented on Apr 7, 2016
Awesome script, thanks! @chuxau, can you post your modified script? I'm after running this against a list too.

@ktamas77
ktamas77 commented on Jul 20, 2016
thank you! perfect.

@dhruvit01
dhruvit01 commented on Aug 5, 2016 • 
I have been trying to use this script in automation. However running into the issues saying
"End-of-central-directory signature not found. Either this file is not a zipfile, or it constitutes one disk of a multi-part archive. In the
latter case the central directory and zipfile comment will be found on the last disk(s) of this archive". Tried many thins to trouble shoot but no luck so far. It seems to have a problem with unzipping.

Any help/Suggestion?

@nickcharlton
nickcharlton commented on Sep 7, 2016 • 
@dhruvit01 and others who might be seeing this issue:

Sometimes the Plugin-Dependencies line gets wrapped (for example, with the github plugin) and instead you end up fetching something like githu instead of github-api. You get the unzip error, because instead of fetching a plugin you get the 404 page.

This is a bit of a pain to filter out. This does the trick, but it could probably be better written:

unzip -p ${f} META-INF/MANIFEST.MF | grep -e "[a-z-]:[0-9]" | tr -d "\r\n " | sed "s/Plugin-Dependencies://" | tr ',' '\n' | awk -F ':' '{ print $1 }'
@eyysee
eyysee commented on Sep 16, 2016
Thanks @nickcharlton, this sorted it the dep issue for me.

@sundy-li
sundy-li commented on Sep 18, 2016
This script is awesome, saving my life!!!!

@iocentos
iocentos commented on Oct 21, 2016
Awesome script. +1

@larrycai
larrycai commented on Dec 6, 2016
excellent, +1, can be easily added into my Dockerfile now

@noroutine
noroutine commented on Dec 22, 2016
For whoever searches for this, make sure you try jenkins rest api first

	curl -X POST \
		--data "<jenkins><install plugin='${name}@latest' /></jenkins>" \
		--header 'Content-Type: text/xml' \
		http://localhost:8080/pluginManager/installNecessaryPlugins

@olvesh
olvesh commented on Feb 19, 2017
Does this gist come with a license?

@BigTexasDork
BigTexasDork commented on Mar 16, 2017
Genius. +1

@dimplerohara
dimplerohara commented on Apr 21, 2017
Hi.. I am a newbie in Devops.. I have installed jenkins after adding alot of proxy settings everywhere.. but when I open web console, after entering the admin password it throws 404, because it is not able to download certain plugins. So now from what I searched I found your script which can download required plugins for jenkins. I have 2 questions here:

How do I exactly know which all plugins needs to be updated?
Can I used your script as-is?
Thanks

@dragomirr
dragomirr commented on Apr 26, 2017
Awesome +1

@pivec
pivec commented on May 1, 2017
@nickcharlton, i tried that, still no luck :/

@hoesler
hoesler commented on May 12, 2017
Published an improved version, if anyone is interested:
https://gist.github.com/hoesler/ed289c9c7f18190b2411e3f2286e23c3

@uttamanand
uttamanand commented on Jun 28, 2017
@noroutine

I tries using jenkins rst api but getting issues.

Command tried -:

curl -X POST -data "" --header 'Content-Type: text/xml' http://localhost:8080/pluginManager/installNecessaryPlugins

ERROR -:

% Total % Received % Xferd Average Speed Time Time Time Current
Dload Upload Total Spent Left Speed
0 0 0 0 0 0 0 0 --:--:-- --:--:-- --:--:-- 0curl: (6) Could not resolve host: latest'
100 390 100 387 100 3 24187 187 --:--:-- --:--:-- --:--:-- 24187

<title>Error 403 No valid crumb was included in the request</title>
HTTP ERROR 403
Problem accessing /pluginManager/installNecessaryPlugins. Reason:

    No valid crumb was included in the request
Powered by Jetty://
@Eldadc
Eldadc commented on Aug 30, 2017
Do you support pulling from an offline folder with the hpi files ?
Thanks

@Eldadc
Eldadc commented on Sep 5, 2017
Does not operate , It copy files to plugin folder but the plugin was not installed in Jenkins,

@averri
averri commented on Oct 27, 2017
It didn't work. The script downloads, but the plugins are not installed.

@dragon788
dragon788 commented on Feb 12, 2018
See the comment on another gist with how to get the crumb, https://gist.github.com/basmussen/8182784#gistcomment-2261919

@lucasproclc
lucasproclc commented on Feb 15, 2018
Anyway to know if this script can add bitbucket? If so, kindly advise.

@vigneshp826
vigneshp826 commented on Feb 21, 2018 • 
Awesome +1.

I installed few plugins using GUI. Am seeing slack.jpi file and slack directory in JENKINS_HOME/plugins directory. But originally the installation is failed due to dependency.

Is there any way to check whether the .hpi is valid or installed correctly before trying this script?

@goginenigvk
goginenigvk commented on Mar 9, 2018
Awesome,
is there any script to check plugins that are installed

@JKrag
JKrag commented on May 1, 2018 • 
@micw Could you be convinced to specify a license on this script? Maybe just an MIT or similar? Without some form of license, it would be all rights reserved, and even the many existing forks are strictly speaking in violation of your copyright, probably even if those forks that are unmodified. Also, no one would be allowed to actually use your really nice script or any of the forks out there.

If you need inspiration, I often find https://choosealicense.com/ very useful.

@wiz4host
wiz4host commented on Nov 1, 2018 • 
Awesome,
is there any script to check plugins that are installed

There are multiple ways to list your Jenkins Plugins:

Way 1: Script console(groovy code):
go to http:<Jenkins_URl>/script
Run below command:

Jenkins.instance.pluginManager.plugins.each{
  plugin ->
    println ("${plugin.getShortName()}")
}
Way 2: Command CLI
Download command-CLI jar from : http://<Jenkins_URL>/jnlpJars/jenkins-cli.jar
Run below command:
java -jar jenkins-cli.jar -s http://<JENKINS_URL>/ list-plugins --username "<Jenkins_USERNAME>" --password "<Jenkins_Password>"

Way 3: Jenkins Python API

import jenkins
import json
server = jenkins.Jenkins('<jenkinsurl>', username='<Jenkins_user>', password='<Jenkins_User_password>')
all_plugins_info=server.get_plugins_info()
for each_plugin in all_plugins_info:
    print each_plugin['shortName']
@blontic
blontic commented on Nov 6, 2018 • 
if you are using a file that contains the name of a plugin on each line you can use this command with the above script
./install_jenkins_plugin.sh $(echo $(cat plugins.txt))

@FilBot3
FilBot3 commented on Dec 27, 2018 • 
@noroutine

For whoever searches for this, make sure you try jenkins rest api first

	curl -X POST \
		--data "<jenkins><install plugin='${name}@latest' /></jenkins>" \
		--header 'Content-Type: text/xml' \
		http://localhost:8080/pluginManager/installNecessaryPlugins
You should update your example to include the Crumb Issuer Header as well.

https://support.cloudbees.com/hc/en-us/articles/219257077-CSRF-Protection-Explained
@wrossmann
wrossmann commented on Feb 25, 2020
Jenkins' docker build has a script for this: https://github.com/jenkinsci/docker/blob/master/install-plugins.sh

@praveen-dwivedi1987
 
Add heading textAdd bold text, <Ctrl+b>Add italic text, <Ctrl+i>
Add a quote, <Ctrl+Shift+.>Add code, <Ctrl+e>Add a link, <Ctrl+k>
Add a bulleted list, <Ctrl+Shift+8>Add a numbered list, <Ctrl+Shift+7>Add a task list, <Ctrl+Shift+l>
Directly mention a user or team
Reference an issue or pull request
Leave a comment
No file chosen
Attach files by dragging & dropping, selecting or pasting them.
Styling with Markdown is supported
Footer
© 2023 GitHub, Inc.
Footer navigation
Terms
Privacy
Security
Status
Docs
Contact GitHub
Pricing
API
Training
Blog
About
