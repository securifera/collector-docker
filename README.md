# collector-docker
Dockerfile for manual installation of Recon collector tools


### BUILD INSTRUCTIONS & README
 docker build --build-arg sshkey="local public key file" --build-arg apikey="Recon API Key" --build-arg gituser="git username" --build-arg gitpwd="git token" -t collector:test1 .
 
 docker run --name collector1 --net=host -v /opt/collector:/opt/collector -d collector:test1


Create "/opt/collector/luigi.cfg" on host volume:

    [worker]
    no_install_shutdown_handler=True
