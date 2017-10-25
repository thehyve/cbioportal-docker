#
# Copyright (c) 2017 The Hyve B.V.
# This code is licensed under the GNU Affero General Public License (AGPL),
# version 3, or (at your option) any later version.
#

FROM httpd:2.4
MAINTAINER Pieter Lukasse <pieter@thehyve.nl>
COPY ./my-httpd.conf /usr/local/apache2/conf/httpd.conf

COPY ./cert.crt /etc/ssl/cbio_https/cert.crt
COPY ./key.key /etc/ssl/cbio_https/key.key


