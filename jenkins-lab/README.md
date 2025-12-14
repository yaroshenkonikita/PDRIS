# Локальная лаборатория Jenkins (PDRIS)

## Что входит в стенд
- **Jenkins** — кастомный образ (JDK 17, Git, Maven, Ansible, sshpass).
- **Nexus Repository Manager** — образ `sonatype/nexus3:3.73.0` с томом `nexus_data`.
- **SonarQube** — `sonarqube:lts-community`.
- **App host (`app`)** — облегчённый Debian с SSH, Python и systemd.

Все контейнеры объединены сетью `jenkins_lab_net`. Состояние Jenkins и Nexus хранится в volumes `jenkins_home`, `nexus_data`, поэтому перезапуски не требуют повторной настройки.

## Быстрый старт
```bash
cd jenkins-lab
docker compose up -d --build
```

## Доступы
| Сервис | Как зайти | Логин | Пароль |
| --- | --- | --- | --- |
| Jenkins | http://localhost:8088 | admin | admin123 |
| Jenkins JNLP | порт 50000 | admin | admin123 |
| Nexus | http://localhost:8081 | admin | admin123 |
| SonarQube | http://localhost:9000 | admin | admin123 |
| App host | `ssh root@localhost -p 2222` | root | admin |
