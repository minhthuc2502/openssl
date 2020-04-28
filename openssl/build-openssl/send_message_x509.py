import os
import time
import uuid
import random
from azure.iot.device import IoTHubDeviceClient, Message, X509
TEMPERATURE = 20.0
HUMIDITY = 60
MSG_TXT = '{{"temperature": {temperature},"humidity": {humidity}}}'
# The connection string for a device should never be stored in code.
# For the sake of simplicity we are creating the X509 connection string
# containing Hostname and Device Id in the following format:
# "HostName=<iothub_host_name>;DeviceId=<device_id>;x509=true"
#hostname = "arm-iot.azure-devices.net;SharedAccessKeyName=device;SharedAccessKey=vw7ID6nS8gIS4wyyhmtp6EOZmGnesU"
hostname='arm-iot.azure-devices.net'
# The device that has been created on the portal using X509 CA signing or Self signing capabilities
device_id = "ArmDevice"

x509 = X509(
    cert_file="/home/minhthuc/Desktop/work-space/control-arm/azure-iot-sdk-c/azure-iot-sdk-c/tools/CACertificates/certs/azure-iot-test-only.chain.ca.ArmDevice.cert.pem",
    key_file="/home/minhthuc/Desktop/work-space/control-arm/azure-iot-sdk-c/azure-iot-sdk-c/tools/CACertificates/private/new-device.key.pem",
    pass_phrase="1234",
)

# The client object is used to interact with your Azure IoT hub.
device_client = IoTHubDeviceClient.create_from_x509_certificate(
    hostname=hostname, device_id=device_id, x509=x509
)
# Connect the client.
device_client.connect()
# send 5 messages with a 1 second pause between each message
for i in range(1, 6):
    temperature = TEMPERATURE + (random.random() * 15)
    humidity = HUMIDITY + (random.random() * 20)
    msg_txt_formatted = MSG_TXT.format(temperature=temperature, humidity=humidity)
    msg = Message(msg_txt_formatted)
    msg.message_id = uuid.uuid4()
    msg.correlation_id = "correlation-1234"
    msg.content_type = "application/json"
    msg.content_encoding = "utf-8"; 
    msg.custom_properties["tornado-warning"] = "yes"
    print( "Sending message: {}".format(msg) )
    device_client.send_message(msg)
    time.sleep(1)

# finally, disconnect
device_client.disconnect()
