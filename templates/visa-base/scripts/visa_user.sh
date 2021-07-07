#!/bin/bash

useradd -m -U -p $(openssl passwd -1 visa) -s /bin/bash visa

