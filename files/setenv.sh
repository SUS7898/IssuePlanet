#!/bin/sh
# Spring Boot 외부 설정 위치 지정.
# /opt/app/config/application.properties 가 WAR 내부 application.properties 보다 우선 적용된다.
export CATALINA_OPTS="$CATALINA_OPTS -Dspring.config.additional-location=file:/opt/app/config/"
