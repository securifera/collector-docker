# collector-docker
Dockerfile for manual installation of Recon collector tools


### BUILD INSTRUCTIONS & README
 docker build --build-arg sshkey="local public key file" --build-arg apikey="Recon API Key" --build-arg gituser="git username" --build-arg gitpwd="git token" -t collector:test1 .
 
 docker run --name collector1 --net=host -v /opt/collector:/opt/collector -d collector:test1
 
 
 
###########################################################################################
Start docker instance with port forward from docker to host on port 2222


```
docker run --name collector1 -p 2222:22 -v /opt/collector:/opt/collector -d collector:test1
```

#################################################
Create a port forward from Collector to Pivot

edit /etc/ssh/sshd_config on pivot to all for all interfaces to forward traffic

```
GatewayPorts clientspecified
```


```
screen -S ssh_session
ssh -t -t -N -i pivot.pem -R *:2222:localhost:2222 -o ServerAliveCountMax=3 <username>@<IP Address>
```

#################################################
If there is an error about signal on main thread with luigi

Create "/opt/collector/luigi.cfg" on host volume:

    [worker]
    no_install_shutdown_handler=True
