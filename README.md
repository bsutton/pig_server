# PiGation

PiGation is a WebServer and front end for running an irrigation system
on the raspberry pi.

PiGation lets you configure garden beds and lights associate those features
with general IO pins on your Rapsberry PI.

Pigation is written in Dart and easy to install.

Start by installing Dart on your raspberry PI.

Once Dart is installed you can install PiGation.

NOTE: you can run up a test system on any linux system as PiGation
comes with a IO simulator that simply logs out any IO PIN changes when
not run on a RiPi.

```bash
dart pub global activate pigation
dart pub global activate dcli_sdk
sudo env PATH="$PATH" dcli install
```

Follow the dcli instructions on adding the ~/.dcli/bin directory to your path.

Now compile pigation.

```bash
dcli compile --package pigation
```


Now run the pigation installer. This will install pigation into /opt/pigation.

As part of the install you need to decide if you will use HTTP or HTTPS to
access PiGation.  If you want to use HTTPS then your PI must be exposed on
the internet (using NAT) with both port 80 and 443 open.

If you don't understand how to configure NAT then just choose HTTP.


```bash
sudo env PATH="$PATH" pig
```

# Accessing 
The pigation server has an embedded front end.

To access the Pigation front end navigate to the IP address of FQDN of
your RiPI from a browser.

`http://mypi`

If you have enabled HTTPS then:
`https://mypi`

# Getting Started
The first thing you need to do is connect the GIO pins to your irrigation
values, you will need a relay device to provide enough power to trigger the vales.

Once the hardware is configured you need to define End Points and Garden Beds

An EndPoint creates a named mapping to a GIO pin on the pie.
Once you have defined you End Points you can go in and configure your
Garden Beds. After which you are ready to water your garden.



# HTTPS
If you have selected HTTPS then the server will attempt to obtain a letsencrypt
certificate when it starts. It will also auto renew the certificate as require.

In order to user HTTPS the following requirements must be met:

Ports 80 and 443 must be exposed to the public internet. This usually requires
the configuration of NAT on your home router.

When installing pigation you should choose a 'Staging' certificate until
you have successfully obtain a certificate.

Once you have obtained a staging certificate you can switch to a live
certificate by running `sudo pig` and switch to a Live certificate.


# deployment

The pig installer installs itself into /opt/pigation.

It also installs a cron job so that the pigation server restarts if
your RiPi reboots.


# Release
Pigation use pub_release to publish to pub.dev.

From the pig_server root directory run: 
```
dart pub global activate pub_release
pub_release
```


# configuration

The /opt/pigation/config/config.yaml file is used to configure the server.

The install creates the config.yaml file based on your answers during the 
install. 
It is generally easier to run `sudo pig` if you need to make config modification
as that command will restart you pigation server with the new config.


# development
You will need a separate config.yaml files for your development environment.

| usage | location |
| ----- | ----- |
| development path | <project root>/config/config.yaml |


The following is a sample for your **development** environment

`<project root>/config/config.yaml`
```yaml
password: XXXXXXXXXXX
path_to_static_content: /home/bsutton/git/pigation/pig_app/build/web
path_to_lets_encrypt_live: /opt/pigation/letsencrypt/live
fqdn: <your local ip>
domain_email: bsutton@onepub.dev
https_port: 10443  # use ports above 1024
http_port: 1080
production: false
binding_address: 0.0.0.0
logger_path: console

```



| setting | purpose |
| ------------ | ----------------- |
| password | hasshed password used to auth the front end app. |
| path_to_static_content | location where the server will look for the sites static web content |
| path_to_lets_encrypt_live | The location to store the lets encrypt certificate. |
| fqdn | The fully qualified domain name of your web site |
|domain_email | The email address we submit to Lets Encrypt so it can send renewal notices and other critical communications. (We do however renew certificates automatically). |
|https_port | The port to listen to https requests on. |
| http_port | The port to listen to http requests on. This port MUST be open as it is required by Lets Encrypt to obtain a certificate |
| production | Controls wheter we obtain a live or staging Lets Encrypt certificate. You should start by setting this to false until you have seen IHAServer successfully obtain a certificate. You can then change the setting to 'true' and restart the IAHServer to obtain a live certificate. **See below for additional information**|
| binding_address | The IP address that IAHServer will listen to. Using 0.0.0.0 tells the PIG Server to listen on all local addresses. If you use a specific address it must be a local addres on the server. |
| logger_path | The path to write log messages to. If you set this value to 'console' log messages are printed to the stdout (the console). This is useful in a development environment |



# Certificates in Development

Within you development environement you are likely to be behind a NAT.
To test the cert aquistion and renewal you will need to forward 
port 443 and 80 from your local router to your development box.

You will need a DNS server with a real domain name and an A record that 
points to your router's public IP.

On Linux, you will need to make the server use ports above 1024 (you can only
listen to ports below 1024 if you are root - not recommended for dev).

I suggest:
80 -> 8080
443 -> 8443

You will need to change the config/config.yaml port settings to match the port
numbers you choose.

You should generally test using a staging certificate until you are certain your configuration
and NAT are set up correctly.

## Run the service locally

To debug the pig server you can simply launch bin/pig.dart --server in your favourite IDE.


# Build on the PI

```bash
dart pub global activate dcli_sdk
udo env PATH="$PATH" dcli install
git clone https://github.com/bsutton/pig_server.git
dcli compile bin/pig.dart
sudo env PATH="$PATH" pig
```

# publishing to pub.dev

The pigation server is intended to be publish to pub.dev to make installation
simple.

We use pub_release to do this.

```
dart pub global activate pub_release
pub_release
```

There is a pub_release hook too/pre_release_hook/build_and_pack_wasm.dart which
builds the wasm target and packs it into the pigation server.