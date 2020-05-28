# Сборка новой базы

1. Скопировать в новую папочку какой-нибудь существующий конфиг.
2. Поднастроить по необходимости.
3. Запустить docker build.

# Загрузка на docker hub

Далее по этой инструкции: https://ropenscilabs.github.io/r-docker-tutorial/04-Dockerhub.html

1. `docker images` - смотрим список образов, находим наш (он будет CREATED только что), запоминаем его `IMAGE_ID`
2. Придумываем имя, например: `cronfy/lamp7.4`
3. Тегируем: `docker tag ТУТ-IMAGE-ID cronfy/lamp7.4`
4. Запушим: `docker push cronfy/lamp7.4`

Готово.

