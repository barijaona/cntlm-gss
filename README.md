# Cntlm with Kerberos support

This is [Cntlm](http://cntlm.sourceforge.net/) **with Kerberos patch applied**.

Dependency: [Kerberos](http://web.mit.edu/kerberos/).

To build:

```
./configure --enable-kerberos
make
sudo make install
```


If Kerberos is compiled to a different location, say, $HOME/usr, compile Cntlm with:

```
./configure --enable-kerberos
export LIBRARY_PATH=$HOME/usr/lib
export C_INCLUDE_PATH=$HOME/usr/include
make
sudo make install
```

To run it, try `cntlm --help` or `cntlm -v` and fix whatever it complains.

## Running against a proxy supporting Kerberos

I have only the following lines in my ctnlm.conf file:

```
Username
Domain
Password
Proxy      proxy.server.domain.com:3128
NoProxy    localhost, 127.0.0.*, 10.*, 192.168.*
Listen     3128
```

The username, domain and password are all unset.

I could start it with `cntlm -a gss` (or  `cntlm -a gss -c /path/to/cntlm.conf`).

## Running against a proxy not supporting Kerberos, but having NTLMv2 support
Whenever I have to change password, I get the output of `cntlm -H`

````
% cntlm -H -u <Username> -d <Domain>
Password:
PassLM          1AD35398BE6565DDB5C4EF70C0593492
PassNT          77B9081511704EE852F94227CF48A793
PassNTLMv2      D5826E9C665C37C80B53397D5C07BBCB   ### Only for user 'Username', domain 'Domain'
````

and put the result into my cntlm.conf file:

```
Username   <Username>
Domain	   <domain>
Proxy      proxy.server.domain.com:3128
PassLM          1AD35398BE6565DDB5C4EF70C0593492
PassNT          77B9081511704EE852F94227CF48A793
PassNTLMv2      D5826E9C665C37C80B53397D5C07BBCB   ### Only for user 'Username', domain 'Domain'
NoProxy    localhost, 127.0.0.*, 10.*, 192.168.*
Listen     3128
```

## Running as an agent on macOS

On macOS, it is safer to run cntlm as an agent rather than having it fork itself from the command line.

The installer installs a .plist in an appropriate location. To have cntlm launch itself at session startup, the following command needs to be entered in the Terminal:

````
launchctl load ~/Library/LaunchAgents/net.sourceforge.cntlm.plist
````


To stop cntlm, for instance when I need to modify the configuration file, I issue the command:

````
launchctl unload ~/Library/LaunchAgents/net.sourceforge.cntlm.plist
````

After modification of the .conf file, I relaunch cntlm with the above mentioned `launchctl load` command.