# Cntlm with Kerberos support

This is [Cntlm](http://cntlm.sourceforge.net/) **with Kerberos patch applied**.

This version also includes improvements made by the original author, David Kubicek, between November 2011 and April 2012, which were published at http://svn.awk.cz/cntlm

It is lighter than the version maintained by Sebastian Matuschka at https://github.com/versat/cntlm. It incorporates a few niceties for macOS users.

Dependency: [Kerberos](http://web.mit.edu/kerberos/).

## How to build

To build:

```
./configure --enable-kerberos
make
sudo make install
```


If Kerberos is compiled to a different location, say, `$HOME/usr`, compile Cntlm with:

```
./configure --enable-kerberos
export LIBRARY_PATH=$HOME/usr/lib
export C_INCLUDE_PATH=$HOME/usr/include
make
sudo make install
```

To run it, try `cntlm --help` or `cntlm -v` and fix whatever it complains.

More documentation is available through `man cntlm`.

### Xcode project for macOS

On macOS, the __cntlm.xcodeproj__ can be opened with Xcode, as an alternative to the `.configure / make` process described above.

- The project will use Xcode's default compiler (`clang`) rather than `gcc`.
- You will find the executable inside the `~/Library/Developer/Xcode/DerivedData` folder.
- `Release` builds  are universal binaries combining Intel and Apple Silicon code.

## Running against a proxy supporting Kerberos

I have only the following lines in my ctnlm.conf file:

```
Username
Domain
Password
Proxy      proxy.server.domain.com:8080
NoProxy    localhost, 127.0.0.*, 10.*, 192.168.*
Listen     3128
```

The username, domain and password are all unset.

I could start it with `cntlm -a gss` (or  `cntlm -a gss -c /path/to/cntlm.conf`).

## Running against a proxy not supporting Kerberos, but having NTLMv2 support

In this case, it is recommended to set the username, the domain name and hashes of the password in the configuration file.

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
Proxy      proxy.server.domain.com:8080
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